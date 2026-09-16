"""Atlas Admin API client that accepts either style of Atlas credentials.

Atlas has two kinds of credentials and this module supports both:

- Programmatic API Keys: a public/private key pair, authenticated with HTTP
  digest.
- Service Accounts: a client id/secret pair, both prefixed with "mdb_sa",
  exchanged for a short-lived OAuth2 bearer token.

The style is detected from the "mdb_sa" prefix, the same way the Terraform
provider detects it, so callers just hand over whichever pair config.yaml holds.
"""

import base64
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

SERVICE_ACCOUNT_PREFIX = 'mdb_sa'
BASE_URL = 'https://cloud.mongodb.com'
TOKEN_URL = f'{BASE_URL}/api/oauth/token'
DEFAULT_API_VERSION = '2023-01-01'

# Renew the bearer token slightly before it expires so a long-running poll
# (e.g. waiting on a sample dataset load) never uses a stale one.
TOKEN_EXPIRY_SKEW_SECONDS = 60


def is_service_account(credential_id):
    """Whether a credential id belongs to a Service Account rather than an API key."""
    return str(credential_id).startswith(SERVICE_ACCOUNT_PREFIX)


class AtlasResponse:
    """The parts of a requests.Response the callers of this module use."""

    def __init__(self, status_code, body):
        self.status_code = status_code
        self._body = body

    def json(self):
        if not self._body:
            return {}
        try:
            return json.loads(self._body)
        except ValueError:
            return {'body': self._body}


class AtlasApi:
    """Minimal Atlas Admin API client, built on the standard library only.

    Staying off `requests` keeps this usable from Terraform provisioners that
    run before the module's Python requirements are installed.
    """

    def __init__(self, credential_id, credential_secret, api_version=DEFAULT_API_VERSION):
        if not credential_id or not credential_secret:
            raise ValueError('Atlas credential id and secret are both required')

        self.credential_id = credential_id
        self.credential_secret = credential_secret
        self.api_version = api_version
        self.uses_service_account = is_service_account(credential_id)

        self._access_token = None
        self._access_token_expires_at = 0

        if self.uses_service_account:
            self._opener = urllib.request.build_opener()
        else:
            password_manager = urllib.request.HTTPPasswordMgrWithDefaultRealm()
            password_manager.add_password(None, BASE_URL, credential_id, credential_secret)
            self._opener = urllib.request.build_opener(
                urllib.request.HTTPDigestAuthHandler(password_manager)
            )

    @classmethod
    def from_env(cls, api_version=DEFAULT_API_VERSION):
        """Build a client from ATLAS_CREDENTIAL_ID / ATLAS_CREDENTIAL_SECRET."""
        return cls(
            os.environ.get('ATLAS_CREDENTIAL_ID', ''),
            os.environ.get('ATLAS_CREDENTIAL_SECRET', ''),
            api_version,
        )

    def get(self, path, api_version=None):
        return self.request('GET', path, api_version=api_version)

    def post(self, path, body=None, api_version=None):
        return self.request('POST', path, body=body, api_version=api_version)

    def patch(self, path, body=None, api_version=None):
        return self.request('PATCH', path, body=body, api_version=api_version)

    def request(self, method, path, body=None, api_version=None):
        url = path if path.startswith('http') else f'{BASE_URL}{path}'
        data = json.dumps(body).encode('utf-8') if body is not None else None

        request = urllib.request.Request(url, data=data, method=method)
        request.add_header('Accept', f'application/vnd.atlas.{api_version or self.api_version}+json')
        if data is not None:
            request.add_header('Content-Type', 'application/json')
        if self.uses_service_account:
            request.add_header('Authorization', f'Bearer {self._bearer_token()}')

        try:
            with self._opener.open(request) as response:
                return AtlasResponse(response.status, response.read().decode('utf-8'))
        except urllib.error.HTTPError as error:
            return AtlasResponse(error.code, error.read().decode('utf-8', 'replace'))

    def _bearer_token(self):
        if self._access_token and time.time() < self._access_token_expires_at:
            return self._access_token

        credentials = f'{self.credential_id}:{self.credential_secret}'.encode('utf-8')
        request = urllib.request.Request(
            TOKEN_URL,
            data=urllib.parse.urlencode({'grant_type': 'client_credentials'}).encode('utf-8'),
            method='POST',
            headers={
                'Authorization': f'Basic {base64.b64encode(credentials).decode("ascii")}',
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json',
            },
        )

        try:
            with urllib.request.urlopen(request) as response:
                payload = json.loads(response.read().decode('utf-8'))
        except urllib.error.HTTPError as error:
            detail = error.read().decode('utf-8', 'replace')
            raise RuntimeError(
                f'Could not get an Atlas access token for Service Account '
                f'{self.credential_id} (HTTP {error.code}): {detail}'
            ) from error

        self._access_token = payload['access_token']
        self._access_token_expires_at = (
            time.time() + int(payload.get('expires_in', 3600)) - TOKEN_EXPIRY_SKEW_SECONDS
        )
        return self._access_token


def describe_credentials(credential_id):
    """Human-readable credential style, for log lines."""
    return 'Service Account' if is_service_account(credential_id) else 'Programmatic API Key'


def exit_on_error(response, context):
    """Abort with the Atlas error payload when a call did not succeed."""
    if response.status_code >= 300:
        print(f'ERROR {response.status_code} while {context}: {response.json()}', file=sys.stderr)
        sys.exit(1)
    return response
