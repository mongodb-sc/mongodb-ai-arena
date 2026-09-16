#!/usr/bin/env python3
"""Raise the database user limit of an Atlas project.

For a shared (non-dedicated) project the limit is not a Terraform-managed
attribute, so it has to be PATCHed through the Admin API instead.

Usage: raise_user_limit.py PROJECT_ID LIMIT
Credentials come from ATLAS_CREDENTIAL_ID / ATLAS_CREDENTIAL_SECRET.
"""

import sys

from atlas_auth import AtlasApi, describe_credentials, exit_on_error

LIMIT_NAME = 'atlas.project.security.databaseAccess.users'


def main():
    if len(sys.argv) != 3:
        print(f'Usage: {sys.argv[0]} PROJECT_ID LIMIT', file=sys.stderr)
        return 1

    project_id, limit = sys.argv[1], int(sys.argv[2])

    try:
        api = AtlasApi.from_env()
    except ValueError as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 1

    print(
        f'Raising {LIMIT_NAME} to {limit} for project {project_id} '
        f'using {describe_credentials(api.credential_id)} credentials...',
        flush=True,
    )
    exit_on_error(
        api.patch(f'/api/atlas/v2/groups/{project_id}/limits/{LIMIT_NAME}', {'value': limit}),
        f'raising {LIMIT_NAME} for project {project_id}',
    )
    print('Limit updated.', flush=True)
    return 0


if __name__ == '__main__':
    sys.exit(main())
