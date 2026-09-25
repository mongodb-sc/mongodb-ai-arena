from flask import Flask, jsonify, request, Response
from flask_cors import CORS
from pymongo import MongoClient
from datetime import datetime, timezone
import os
from dotenv import load_dotenv
import logging
import csv
from io import StringIO
import math
import requests as http_requests

# Load environment variables
load_dotenv()

# Initialize Flask app (remove static folder configuration)
app = Flask(__name__)

# Configure CORS to allow requests from your React frontend
# Expose Content-Disposition header so frontend can read filenames
CORS(app, origins=['*'], expose_headers=['Content-Disposition'])  # In production, specify your React app's domain

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# MongoDB configuration
MONGODB_URI = os.getenv('MONGODB_URI')
DB_NAME = os.getenv('DB_NAME')
PARTICIPANTS_COLLECTION = os.getenv('PARTICIPANTS')
USER_DETAILS_COLLECTION = os.getenv('USER_DETAILS', 'user_details')
ARENA_SHARED_DB = os.getenv('ARENA_SHARED_DB', 'arena_shared')
SCENARIO_CONFIG_COLLECTION = os.getenv('SCENARIO_CONFIG_COLLECTION', 'scenario_config')

# MongoDB client
client = MongoClient(MONGODB_URI)
db = client[DB_NAME]
participants_collection = db[PARTICIPANTS_COLLECTION]
user_details_collection = db[USER_DETAILS_COLLECTION]

# Arena shared database for scenario_config
arena_shared_db = client[ARENA_SHARED_DB]
scenario_config_collection = arena_shared_db[SCENARIO_CONFIG_COLLECTION]

# Skill badge configuration
SKILL_BADGE_ENABLED = os.getenv('SKILL_BADGE_ENABLED', 'false').lower() == 'true'
SCORPION_API_TOKEN = os.getenv('SCORPION_API_TOKEN', '')
SCORPION_EXAM_ID = os.getenv('SCORPION_EXAM_ID', '')
SCORPION_BASE_URL = os.getenv('SCORPION_BASE_URL', 'https://scorpion.caveon.com')
SCORPION_ASSESSMENT_URL = os.getenv('SCORPION_ASSESSMENT_URL', '')
CREDLY_API_TOKEN = os.getenv('CREDLY_API_TOKEN', '')
CREDLY_ORG_ID = os.getenv('CREDLY_ORG_ID', '')
CREDLY_BADGE_TEMPLATE_ID = os.getenv('CREDLY_BADGE_TEMPLATE_ID', '')
CREDLY_BASE_URL = os.getenv('CREDLY_BASE_URL', 'https://api.credly.com')
SKILL_BADGE_BONUS_NAME = os.getenv('SKILL_BADGE_BONUS_NAME', 'skill-badge')
SKILL_BADGE_BONUS_POINTS = int(os.getenv('SKILL_BADGE_BONUS_POINTS', '50'))
SKILL_BADGE_MAX_ATTEMPTS = int(os.getenv('SKILL_BADGE_MAX_ATTEMPTS', '1'))

skill_badge_collection = arena_shared_db['skill_badge_deliveries']
results_collection_shared = arena_shared_db['results']

# Helper function to format milliseconds to human-readable duration
def format_time(milliseconds):
    """
    Convert milliseconds to hours and minutes format like the frontend.
    Examples: "25m", "1h 30m", "45s"
    """
    if milliseconds == 0:
        return '0m'
    
    seconds = math.floor(milliseconds / 1000)
    hours = math.floor(seconds / 3600)
    minutes = math.floor((seconds % 3600) / 60)
    remaining_seconds = seconds % 60
    
    result = ''
    if hours > 0:
        result += f'{hours}h '
    if minutes > 0:
        result += f'{minutes}m'
    elif hours == 0 and remaining_seconds > 0:
        result += f'{remaining_seconds}s'
    
    return result.strip()

@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    try:
        # Test MongoDB connection
        client.admin.command('ping')
        return jsonify({'status': 'healthy', 'database': 'connected'}), 200
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500

@app.route('/api/participants', methods=['GET'])
def get_participants():
    """Get participants that are taken or don't have a taken field"""
    try:
        # Retrieve participants that are either taken=true or don't have taken field
        filter_query = {"$or": [{"taken": True}, {"taken": {"$exists": False}}]}
        participants = list(participants_collection.find(
            filter_query, 
            {'_id': 1, 'name': 1, 'taken': 1, 'decommissioned': 1, 'decommissioned_timestamp': 1}
        ).sort([("taken_timestamp", -1), ("name", 1)]))
        
        logger.info(f"Retrieved {len(participants)} participants matching filter")
        return jsonify({
            'success': True,
            'data': participants,
            'count': len(participants)
        }), 200
        
    except Exception as e:
        logger.error(f"Error retrieving participants: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/participants/available', methods=['GET'])
def get_available_participants_count():
    """Get available and active participant counts"""
    try:
        # Available = users with taken: false and not decommissioned
        available_count = participants_collection.count_documents({
            "$and": [
                {"taken": False},
                {"$or": [{"decommissioned": {"$ne": True}}, {"decommissioned": {"$exists": False}}]}
            ]
        })
        
        # Active (non-decommissioned) = all users that are not decommissioned
        active_count = participants_collection.count_documents({
            "$or": [{"decommissioned": {"$ne": True}}, {"decommissioned": {"$exists": False}}]
        })
        
        # Total participants (including decommissioned)
        total_count = participants_collection.count_documents({})
        
        logger.info(f"Available: {available_count}, Active: {active_count}, Total: {total_count}")
        return jsonify({
            'success': True,
            'available_count': available_count,
            'active_count': active_count,
            'total_count': total_count,
            'message': f'{available_count} available, {active_count} active, {total_count} total'
        }), 200
        
    except Exception as e:
        logger.error(f"Error counting participants: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/participants/take', methods=['POST'])
def take_participant():
    """
    Find an available participant and mark as taken
    Expected JSON payload:
    {
        "name": "participant_name", 
        "email": "participant_email"
    }
    """
    try:
        # Get JSON data from request
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'No JSON data provided'
            }), 400
            
        # Validate required fields
        required_fields = ['name', 'email']
        missing_fields = [field for field in required_fields if field not in data or not data[field]]
        
        if missing_fields:
            return jsonify({
                'success': False,
                'error': f'Missing required fields: {", ".join(missing_fields)}'
            }), 400

        # Ensure name/email are plain strings. Without this check, a client could
        # send a JSON object (e.g. {"$ne": false}) as the value, which would get
        # stored verbatim in MongoDB and later crash the frontend when rendered
        # (React error #31: "Objects are not valid as a React child").
        name = data['name']
        email = data['email']

        if not isinstance(name, str) or not isinstance(email, str):
            return jsonify({
                'success': False,
                'error': 'Fields "name" and "email" must be strings'
            }), 400

        name = name.strip()
        email = email.strip()

        if not name or not email:
            return jsonify({
                'success': False,
                'error': 'Fields "name" and "email" cannot be empty'
            }), 400

        # Create update document for participants collection (no email)
        participant_update_data = {
            'name': name,
            'taken': True,
            'taken_timestamp': datetime.now(timezone.utc).isoformat()
        }
        
        # Use findOneAndUpdate with atomic operation to prevent race conditions
        updated_participant = participants_collection.find_one_and_update(
            {'taken': False},
            {'$set': participant_update_data},
            return_document=True,
            projection={'_id': 1, 'name': 1, 'taken': 1, 'taken_timestamp': 1}
        )
        
        if not updated_participant:
            return jsonify({
                'success': False,
                'error': 'No available participants found'
            }), 404
        
        # Store email and other details in user_details collection
        participant_id = updated_participant['_id']
        user_details_data = {
            'name': name,
            'email': email,
            'timestamp': datetime.now(timezone.utc)
        }
        
        user_details_collection.update_one(
            {'_id': participant_id},
            {'$set': user_details_data},
            upsert=True
        )
        
        # Return response without email for security
        response_data = {
            '_id': updated_participant['_id'],
            'name': updated_participant['name'],
            'taken': updated_participant['taken'],
            'taken_timestamp': updated_participant['taken_timestamp']
        }
            
        logger.info(f"Successfully assigned participant {participant_id} to {name}")
        return jsonify({
            'success': True,
            'message': f'Participant successfully assigned to {name}',
            'data': response_data
        }), 200
        
    except Exception as e:
        logger.error(f"Error taking participant: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/results', methods=['GET'])
def get_results():
    """
    Return leaderboard results based on LEADERBOARD env variable.
    If LEADERBOARD == 'score', return score_leaderboard view with aggregated points.
    If LEADERBOARD == 'timed', return timed_leaderboard view.
    Supports ?format=csv query parameter to download as CSV.
    """
    try:
        leaderboard = os.getenv('LEADERBOARD', 'timed')
        format_type = request.args.get('format', 'json').strip().lower()
        logger.info(f"[getResults] Request received with format={format_type}, leaderboard={leaderboard}")
        
        # Validate leaderboard type
        if leaderboard not in ['score', 'timed']:
            logger.warning(f"[getResults] Invalid LEADERBOARD env value '{leaderboard}', defaulting to 'timed'")
            leaderboard = 'timed'
        
        # Use different views based on leaderboard type
        view_name = 'score_leaderboard' if leaderboard == 'score' else 'timed_leaderboard'
        leaderboard_collection = db[view_name]
        
        # For timed leaderboard, include _id (it's the username/user_id)
        # For score leaderboard, exclude _id (not needed for aggregation)
        projection = {'_id': 0} if leaderboard == 'score' else {}
        data = list(leaderboard_collection.find({}, projection))

        # Look up skill badge earners for bonus point injection
        badge_earners = set()
        if SKILL_BADGE_ENABLED:
            try:
                for d in skill_badge_collection.find({'bonus_awarded': True}, {'_id': 1}):
                    badge_earners.add(d['_id'])
            except Exception as e:
                logger.warning(f"[getResults] Could not fetch badge earners: {e}")

        if leaderboard == 'score':
            # Aggregate points by username for score leaderboard
            points_by_username = {}
            for item in data:
                users = item.get('users', [])
                for user in users:
                    display_name = user.get('user') or user.get('username')
                    points = user.get('points', 0)

                    if display_name in points_by_username:
                        points_by_username[display_name] += points
                    else:
                        points_by_username[display_name] = points

            # Apply skill badge bonus to earners
            # The view keys by display name, so resolve participant_id -> display name
            for username in badge_earners:
                participant = participants_collection.find_one({'_id': username}, {'name': 1})
                display_name = participant.get('name', username) if participant else username
                if display_name in points_by_username:
                    points_by_username[display_name] += SKILL_BADGE_BONUS_POINTS
                elif username in points_by_username:
                    points_by_username[username] += SKILL_BADGE_BONUS_POINTS
                else:
                    points_by_username[display_name] = SKILL_BADGE_BONUS_POINTS

            # Convert to sorted array (sorted by points descending)
            sorted_points_array = sorted(points_by_username.items(), key=lambda x: x[1], reverse=True)
            
            if format_type == 'csv':
                # Return CSV format
                output = StringIO()
                fieldnames = ['rank', 'name', 'total_points']
                writer = csv.DictWriter(output, fieldnames=fieldnames)
                writer.writeheader()
                
                for rank, (name, points) in enumerate(sorted_points_array, start=1):
                    writer.writerow({
                        'rank': rank,
                        'name': name,
                        'total_points': points
                    })
                
                output.seek(0)
                timestamp = datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')
                filename = f'competition_results_{timestamp}.csv'
                
                logger.info(f"[getResults] SUCCESS: score leaderboard CSV with {len(sorted_points_array)} results")
                
                return Response(
                    output.getvalue(),
                    mimetype='text/csv',
                    headers={'Content-Disposition': f'attachment; filename={filename}'}
                )
            else:
                # Return JSON format
                sorted_points_by_username = dict(sorted_points_array)
                items = {
                    'results': sorted_points_by_username,
                    'data': data,
                    'leaderboardType': 'score'
                }
        else:
            # For timed leaderboard — badge earners already get +1 exercise count
            # from the skill-badge result document in the view. But ensure participants
            # who ONLY have the badge (no exercises yet) still appear on the board.
            if SKILL_BADGE_ENABLED and badge_earners:
                existing_users = {item.get('_id') for item in data}
                for username in badge_earners:
                    if username not in existing_users:
                        participant = participants_collection.find_one({'_id': username}, {'name': 1})
                        display_name = participant.get('name', username) if participant else username
                        data.append({
                            '_id': username,
                            'name': display_name,
                            'count': 1,
                            'delta': 0,
                            'firstTimestamp': datetime.now(timezone.utc),
                            'lastTimestamp': datetime.now(timezone.utc),
                        })
                # Re-sort by total score (exercises + bonus for earners), then shortest time
                def timed_sort_key(x):
                    count = x.get('count', 0)
                    total = count + SKILL_BADGE_BONUS_POINTS if x.get('_id') in badge_earners else count
                    return (-total, x.get('delta', 0))
                data.sort(key=timed_sort_key)

            if format_type == 'csv':
                # Return CSV format
                output = StringIO()
                fieldnames = ['rank', 'user_id', 'username', 'name', 'exercises_completed', 'duration', 'duration_ms', 'first_timestamp', 'last_timestamp']
                writer = csv.DictWriter(output, fieldnames=fieldnames)
                writer.writeheader()
                
                for rank, item in enumerate(data, start=1):
                    delta_ms = item.get('delta', 0)
                    user_id = item.get('_id', '')
                    writer.writerow({
                        'rank': rank,
                        'user_id': user_id,
                        'username': user_id,  # _id is the username in timed_leaderboard view
                        'name': item.get('name', user_id),
                        'exercises_completed': item.get('count', 0),
                        'duration': format_time(delta_ms),
                        'duration_ms': delta_ms,
                        'first_timestamp': item.get('firstTimestamp', ''),
                        'last_timestamp': item.get('lastTimestamp', '')
                    })
                
                output.seek(0)
                timestamp = datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')
                filename = f'competition_results_{timestamp}.csv'
                
                logger.info(f"[getResults] SUCCESS: timed leaderboard CSV with {len(data)} results")
                
                return Response(
                    output.getvalue(),
                    mimetype='text/csv',
                    headers={'Content-Disposition': f'attachment; filename={filename}'}
                )
            else:
                # Return JSON format
                items = {
                    'results': data,
                    'leaderboardType': 'timed'
                }
        
        # Calculate result count for logging
        result_count = len(items['results']) if isinstance(items['results'], list) else len(items['results'])
        logger.info(f"[getResults] SUCCESS: {items['leaderboardType']} leaderboard response sent with {result_count} results")
        
        return jsonify(items), 200
        
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        logger.error(f"[getResults] ERROR: Failed to process {os.getenv('LEADERBOARD', 'timed')} leaderboard request: {str(e)}")
        logger.error(f"[getResults] ERROR DETAILS: {error_details}")
        return jsonify({
            'success': False,
            'message': str(e),
            'error': str(e)
        }), 500

@app.route('/api/admin/leaderboard/download', methods=['GET'])
def download_user_leaderboard_csv():
    """
    Download user_leaderboard view as CSV.
    Simple export of the user_leaderboard view data.
    """
    try:
        # Get data from user_leaderboard view
        user_leaderboard_collection = db['user_leaderboard']
        user_data = list(user_leaderboard_collection.find({}))
        
        # Create CSV in memory
        output = StringIO()
        
        # Define CSV headers based on user_leaderboard view structure
        fieldnames = ['user_id', 'name', 'email', 'exercises_solved']
        
        writer = csv.DictWriter(output, fieldnames=fieldnames)
        writer.writeheader()
        
        # Write user data
        for user in user_data:
            row = {
                'user_id': user.get('_id', ''),
                'name': user.get('name', ''),
                'email': user.get('email', ''),
                'exercises_solved': user.get('exercisesSolved', 0)
            }
            writer.writerow(row)
        
        # Prepare the response
        output.seek(0)
        timestamp = datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')
        filename = f'user_list_{timestamp}.csv'
        
        logger.info(f"Generating user list CSV with {len(user_data)} users")
        
        return Response(
            output.getvalue(),
            mimetype='text/csv',
            headers={'Content-Disposition': f'attachment; filename={filename}'}
        )
        
    except Exception as e:
        logger.error(f"Error generating user_leaderboard CSV: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/admin/leaderboard/exclude', methods=['POST'])
def exclude_from_leaderboard():
    """
    Exclude or include a participant from/to the leaderboard.
    Expected JSON payload:
    {
        "identifier": "user_id or name",
        "exclude": true/false  # true to exclude (leaderboard: false), false to include (remove leaderboard field or set to true)
    }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'No JSON data provided'
            }), 400
        
        identifier = data.get('identifier', '').strip()
        exclude = data.get('exclude', True)
        
        if not identifier:
            return jsonify({
                'success': False,
                'error': 'Identifier (user ID or name) is required'
            }), 400
        
        # Try to find participant by _id first, then by name
        participant = participants_collection.find_one({'_id': identifier})
        
        if not participant:
            # Try to find by name (case-insensitive)
            participant = participants_collection.find_one({'name': {'$regex': f'^{identifier}$', '$options': 'i'}})
        
        if not participant:
            return jsonify({
                'success': False,
                'error': f'No participant found with identifier: {identifier}'
            }), 404
        
        participant_id = participant['_id']
        participant_name = participant.get('name', participant_id)
        
        # Update the leaderboard field
        if exclude:
            # Set leaderboard: false to exclude from leaderboard
            update_result = participants_collection.update_one(
                {'_id': participant_id},
                {'$set': {'leaderboard': False}}
            )
            action = 'excluded from'
        else:
            # Remove leaderboard field or set to true to include in leaderboard
            update_result = participants_collection.update_one(
                {'_id': participant_id},
                {'$unset': {'leaderboard': ''}}
            )
            action = 'included in'
        
        if update_result.modified_count > 0:
            logger.info(f"Participant {participant_id} ({participant_name}) {action} leaderboard")
            return jsonify({
                'success': True,
                'message': f'Participant "{participant_name}" (ID: {participant_id}) has been {action} the leaderboard',
                'participant': {
                    '_id': participant_id,
                    'name': participant_name,
                    'leaderboard': not exclude
                }
            }), 200
        else:
            # No modification means the field was already in the desired state
            return jsonify({
                'success': True,
                'message': f'Participant "{participant_name}" (ID: {participant_id}) is already {action} the leaderboard',
                'participant': {
                    '_id': participant_id,
                    'name': participant_name,
                    'leaderboard': not exclude
                }
            }), 200
        
    except Exception as e:
        logger.error(f"Error updating leaderboard exclusion: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/admin/leaderboard/status', methods=['GET'])
def get_leaderboard_status():
    """
    Get all participants and their leaderboard status.
    Returns list of participants with their current leaderboard inclusion status.
    """
    try:
        # Get all participants (including decommissioned ones for admin management)
        participants = list(participants_collection.find(
            {},
            {'_id': 1, 'name': 1, 'leaderboard': 1, 'taken': 1, 'decommissioned': 1}
        ).sort('name', 1))
        
        # Process participants to determine leaderboard status
        result = []
        for participant in participants:
            # If leaderboard field is explicitly False, participant is excluded
            # Otherwise, participant is included (default behavior)
            is_excluded = participant.get('leaderboard') == False
            
            result.append({
                '_id': participant['_id'],
                'name': participant.get('name', participant['_id']),
                'excluded': is_excluded,
                'taken': participant.get('taken'),  # Don't default to False - None means CSV user
                'decommissioned': participant.get('decommissioned', False)
            })
        
        logger.info(f"Retrieved leaderboard status for {len(result)} participants")
        return jsonify({
            'success': True,
            'data': result,
            'count': len(result)
        }), 200
        
    except Exception as e:
        logger.error(f"Error retrieving leaderboard status: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/admin/prizes/close-date', methods=['GET'])
def get_prize_close_date():
    """
    Get the current prize close date from scenario_config.
    Returns the close_on field from leaderboard if it exists.
    MongoDB stores close_on as ISODate (UTC), we convert it to ISO string for JSON.
    """
    try:
        # Find the scenario config document
        config = scenario_config_collection.find_one({})
        
        if not config:
            return jsonify({
                'success': False,
                'error': 'No scenario config found'
            }), 404
        
        leaderboard = config.get('leaderboard', {})
        close_on_date = leaderboard.get('close_on')
        
        # Convert MongoDB Date object to ISO string if it exists
        close_on_iso = None
        if close_on_date:
            if isinstance(close_on_date, datetime):
                # MongoDB Date object - convert to ISO string with Z suffix for UTC
                if close_on_date.tzinfo is None:
                    # Naive datetime, assume UTC and add Z
                    close_on_iso = close_on_date.isoformat() + 'Z'
                else:
                    # Aware datetime, convert to UTC if needed
                    utc_date = close_on_date.astimezone(timezone.utc)
                    close_on_iso = utc_date.isoformat().replace('+00:00', 'Z')
            else:
                # Already a string (for backwards compatibility)
                close_on_iso = close_on_date
        
        logger.info(f"Retrieved prize close date: {close_on_iso}")
        return jsonify({
            'success': True,
            'close_on': close_on_iso
        }), 200
        
    except Exception as e:
        logger.error(f"Error retrieving prize close date: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/admin/prizes/close-date', methods=['POST'])
def set_prize_close_date():
    """
    Set or update the prize close date in scenario_config.
    Expected JSON payload:
    {
        "close_on": "ISO 8601 datetime string"
    }
    The timezone parameter is accepted but not stored (used only for conversion to UTC).
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'No JSON data provided'
            }), 400
        
        close_on = data.get('close_on')
        
        if not close_on:
            return jsonify({
                'success': False,
                'error': 'close_on field is required'
            }), 400
        
        # Validate and parse the date format
        try:
            # Parse ISO string to Python datetime (UTC)
            close_date = datetime.fromisoformat(close_on.replace('Z', '+00:00'))
        except ValueError:
            return jsonify({
                'success': False,
                'error': 'Invalid date format. Use ISO 8601 format.'
            }), 400
        
        # Update the scenario config with the new close_on date as MongoDB Date object
        # MongoDB will automatically store the datetime as ISODate (UTC)
        update_result = scenario_config_collection.update_one(
            {},
            {'$set': {
                'leaderboard.close_on': close_date  # Store as MongoDB ISODate (UTC)
            }},
            upsert=False
        )
        
        if update_result.matched_count == 0:
            return jsonify({
                'success': False,
                'error': 'No scenario config found to update'
            }), 404
        
        logger.info(f"Updated prize close date to: {close_date.isoformat()}")
        return jsonify({
            'success': True,
            'message': f'Prize close date updated successfully',
            'close_on': close_date.isoformat()
        }), 200
        
    except Exception as e:
        logger.error(f"Error updating prize close date: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/users/progress', methods=['GET'])
def get_users_progress():
    """
    Get progress for all active users, identifying those who are stuck or haven't started.
    A user is considered stuck if they haven't completed an exercise in the last 10 minutes.
    Excludes decommissioned users and users with leaderboard: false.
    """
    try:
        # Get all active participants (taken, not decommissioned, leaderboard not false)
        active_participants = list(participants_collection.find(
            {
                'taken': True,
                '$and': [
                    {'$or': [
                        {'decommissioned': {'$exists': False}},
                        {'decommissioned': False}
                    ]},
                    {'$or': [
                        {'leaderboard': {'$exists': False}},
                        {'leaderboard': True}
                    ]}
                ]
            },
            {'_id': 1, 'name': 1}
        ))

        results_collection = db['results']
        current_time = datetime.now(timezone.utc)
        stuck_threshold_minutes = 10

        user_progress = []

        for participant in active_participants:
            username = participant['_id']
            participant_name = participant.get('name', username)

            # Get all results for this user, sorted by timestamp
            user_results = list(results_collection.find(
                {'username': username}
            ).sort('timestamp', -1))

            exercises_completed = len(user_results)
            status = 'not_started'
            last_activity = None
            last_exercise = None
            minutes_since_last = None

            if exercises_completed > 0:
                # Get the most recent result
                latest_result = user_results[0]
                last_activity = latest_result.get('timestamp')
                last_exercise = latest_result.get('name')

                # Calculate time since last activity
                if last_activity:
                    if isinstance(last_activity, str):
                        last_activity_dt = datetime.fromisoformat(last_activity.replace('Z', '+00:00'))
                    else:
                        last_activity_dt = last_activity

                    # Make sure both datetimes are timezone-aware for comparison
                    if last_activity_dt.tzinfo is None:
                        # If naive, assume UTC
                        last_activity_dt = last_activity_dt.replace(tzinfo=timezone.utc)

                    time_diff = current_time - last_activity_dt
                    minutes_since_last = time_diff.total_seconds() / 60

                    if minutes_since_last > stuck_threshold_minutes:
                        status = 'stuck'
                    else:
                        status = 'active'

            user_progress.append({
                'username': username,
                'name': participant_name,
                'exercises_completed': exercises_completed,
                'last_exercise': last_exercise,
                'last_activity': last_activity.isoformat() if last_activity else None,
                'minutes_since_last': round(minutes_since_last, 1) if minutes_since_last else None,
                'status': status
            })

        # Sort by status priority (stuck first, then not_started, then active)
        status_priority = {'stuck': 0, 'not_started': 1, 'active': 2}
        user_progress.sort(key=lambda x: (status_priority.get(x['status'], 3), -x['exercises_completed']))

        # Count by status
        stuck_count = sum(1 for u in user_progress if u['status'] == 'stuck')
        not_started_count = sum(1 for u in user_progress if u['status'] == 'not_started')
        active_count = sum(1 for u in user_progress if u['status'] == 'active')

        logger.info(f"Retrieved progress for {len(user_progress)} users: {stuck_count} stuck, {not_started_count} not started, {active_count} active")

        return jsonify({
            'success': True,
            'users': user_progress,
            'summary': {
                'total': len(user_progress),
                'stuck': stuck_count,
                'not_started': not_started_count,
                'active': active_count
            }
        }), 200

    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        logger.error(f"Error retrieving user progress: {str(e)}")
        logger.error(f"Error details: {error_details}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/results/user/<username>', methods=['GET'])
def get_user_results(username):
    """
    Get all results for a specific user directly from the results collection.
    Returns exercises completed by the user with participant information.
    """
    try:
        # Get results directly from results collection
        results_collection = db['results']

        # Find all results for this user
        user_results = list(results_collection.find(
            {'username': username},
            {'_id': 0}  # Exclude MongoDB _id field
        ).sort('timestamp', 1))  # Sort by timestamp ascending

        if not user_results:
            return jsonify({
                'success': False,
                'message': f'No results found for user: {username}'
            }), 404

        # Get participant info
        participant = participants_collection.find_one(
            {'_id': username},
            {'_id': 1, 'name': 1, 'leaderboard': 1}
        )

        # Check if user should be excluded from leaderboard
        if participant and participant.get('leaderboard') == False:
            return jsonify({
                'success': False,
                'message': f'User {username} is excluded from leaderboard'
            }), 403

        participant_name = participant.get('name', username) if participant else username

        # Count distinct exercise names so duplicate/repeated submissions of
        # the same exercise aren't double-counted in "Total Exercises Completed"
        distinct_exercise_count = len({r.get('name') for r in user_results})

        logger.info(f"Retrieved {len(user_results)} results ({distinct_exercise_count} distinct exercises) for user {username}")
        return jsonify({
            'success': True,
            'username': username,
            'participant_name': participant_name,
            'results': user_results,
            'count': distinct_exercise_count
        }), 200

    except Exception as e:
        logger.error(f"Error retrieving results for user {username}: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/admin/database/restore', methods=['POST'])
def restore_user_databases():
    """
    Restore databases for selected users by dropping and recreating them from the sample database.
    Expected JSON payload:
    {
        "user_ids": ["user1", "user2", ...]
    }
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({
                'success': False,
                'error': 'No JSON data provided'
            }), 400

        user_ids = data.get('user_ids', [])

        if not user_ids or not isinstance(user_ids, list):
            return jsonify({
                'success': False,
                'error': 'user_ids field is required and must be a list'
            }), 400

        if len(user_ids) == 0:
            return jsonify({
                'success': False,
                'error': 'At least one user ID must be provided'
            }), 400

        # Get the sample database name (default to sample_airbnb)
        sample_database = os.getenv('SAMPLE_DATABASE', 'sample_airbnb')

        # Verify that the sample database exists
        databases = client.list_database_names()
        if sample_database not in databases:
            return jsonify({
                'success': False,
                'error': f'Sample database "{sample_database}" not found'
            }), 404

        # Get collections from the sample database
        sample_db = client[sample_database]
        collections_list = sample_db.list_collection_names()

        # Filter out system collections
        collections_to_copy = [col for col in collections_list if not col.startswith('system.')]

        if not collections_to_copy:
            return jsonify({
                'success': False,
                'error': f'No collections found in sample database "{sample_database}"'
            }), 404

        restored_databases = []
        errors = []

        for user_id in user_ids:
            try:
                # Verify the user exists in participants
                participant = participants_collection.find_one({'_id': user_id})
                if not participant:
                    errors.append(f"User '{user_id}' not found in participants collection")
                    continue

                # Get the user's database
                user_db = client[user_id]

                # Check if database exists
                if user_id in databases:
                    # Delete all documents from each collection instead of dropping the database
                    # This preserves indexes
                    user_collections = user_db.list_collection_names()
                    for collection_name in user_collections:
                        if not collection_name.startswith('system.'):
                            delete_result = user_db[collection_name].delete_many({})
                            logger.info(f"Deleted {delete_result.deleted_count} documents from {user_id}.{collection_name}")
                else:
                    logger.info(f"Database '{user_id}' does not exist, will create new one")

                # Restore the database by copying collections from sample database
                for collection in collections_to_copy:
                    # Use aggregation with $out to copy the collection
                    # This will recreate the collection with data while preserving indexes
                    sample_db[collection].aggregate([
                        {'$out': {'db': user_id, 'coll': collection}}
                    ])

                restored_databases.append(user_id)
                logger.info(f"Successfully restored database for user: {user_id}")

            except Exception as e:
                error_msg = f"Error restoring database for user {user_id}: {str(e)}"
                errors.append(error_msg)
                logger.error(error_msg)

        # Prepare response message
        if restored_databases:
            message = f"Successfully restored {len(restored_databases)} database(s): {', '.join(restored_databases)}"
            if errors:
                message += f". {len(errors)} error(s) occurred."
        else:
            message = "No databases were restored"

        logger.info(f"Database restore completed. Restored: {len(restored_databases)}, Errors: {len(errors)}")

        return jsonify({
            'success': len(restored_databases) > 0,
            'message': message,
            'restored': restored_databases,
            'errors': errors,
            'restored_count': len(restored_databases),
            'error_count': len(errors)
        }), 200 if len(restored_databases) > 0 else 500

    except Exception as e:
        logger.error(f"Error in database restore endpoint: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# ===== Skill Badge Endpoints =====

def _credly_auth_headers():
    """Build Basic auth headers for Credly API (token as username, empty password)."""
    import base64
    credentials = base64.b64encode(f"{CREDLY_API_TOKEN}:".encode()).decode()
    return {'Authorization': f'Basic {credentials}', 'Accept': 'application/json'}

_badge_metadata_cache = {}

def _fetch_badge_metadata():
    """Fetch badge template metadata from Credly API (cached)."""
    if _badge_metadata_cache:
        return _badge_metadata_cache

    if not CREDLY_API_TOKEN or not CREDLY_ORG_ID or not CREDLY_BADGE_TEMPLATE_ID:
        return None

    try:
        url = f"{CREDLY_BASE_URL}/v1/organizations/{CREDLY_ORG_ID}/badge_templates/{CREDLY_BADGE_TEMPLATE_ID}"
        resp = http_requests.get(url, headers=_credly_auth_headers(), timeout=10)
        if resp.ok:
            data = resp.json().get('data', resp.json())
            _badge_metadata_cache.update({
                'name': data.get('name', ''),
                'description': data.get('description', ''),
                'image_url': data.get('image_url', ''),
                'skills': [s if isinstance(s, str) else s.get('name', '') for s in data.get('skills', [])],
                'url': data.get('url', ''),
            })
            logger.info(f"Fetched Credly badge metadata: {_badge_metadata_cache.get('name')}")
            return _badge_metadata_cache
        else:
            logger.warning(f"Credly badge metadata fetch failed: {resp.status_code}")
    except Exception as e:
        logger.warning(f"Error fetching Credly badge metadata: {e}")
    return None

def _lookup_credly_badge(participant_email):
    """Look up issued Credly badge for a participant by email. Returns accept_badge_url and state."""
    if not CREDLY_API_TOKEN or not CREDLY_ORG_ID or not CREDLY_BADGE_TEMPLATE_ID or not participant_email:
        return None

    try:
        url = (f"{CREDLY_BASE_URL}/v1/organizations/{CREDLY_ORG_ID}/badges"
               f"?filter=badge_template_id::{CREDLY_BADGE_TEMPLATE_ID}"
               f"|recipient_email::{participant_email}")
        resp = http_requests.get(url, headers=_credly_auth_headers(), timeout=10)
        if resp.ok:
            badges = resp.json().get('data', [])
            if badges:
                badge = badges[0]
                return {
                    'credly_badge_id': badge.get('id'),
                    'accept_badge_url': badge.get('accept_badge_url', ''),
                    'badge_url': badge.get('badge_url', ''),
                    'state': badge.get('state', 'unknown'),
                    'issued_at': badge.get('issued_at'),
                }
        return None
    except Exception as e:
        logger.warning(f"Error looking up Credly badge: {e}")
        return None

@app.route('/api/skill-badge/config', methods=['GET'])
def get_skill_badge_config():
    """Return public skill badge configuration with Credly badge metadata."""
    badge_meta = _fetch_badge_metadata() if SKILL_BADGE_ENABLED else None
    return jsonify({
        'enabled': SKILL_BADGE_ENABLED,
        'bonus_points': SKILL_BADGE_BONUS_POINTS,
        'max_attempts': SKILL_BADGE_MAX_ATTEMPTS,
        'badge_template_id': CREDLY_BADGE_TEMPLATE_ID,
        'badge': badge_meta,
    }), 200

@app.route('/api/skill-badge/start', methods=['POST'])
def start_skill_badge():
    """Create a Scorpion delivery for a participant."""
    if not SKILL_BADGE_ENABLED:
        return jsonify({'success': False, 'error': 'Skill badge is not enabled'}), 404

    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No JSON data provided'}), 400

        participant_id = data.get('participant_id', '').strip()
        if not participant_id:
            return jsonify({'success': False, 'error': 'participant_id is required'}), 400

        participant = participants_collection.find_one({'_id': participant_id})
        if not participant:
            return jsonify({'success': False, 'error': f'Participant {participant_id} not found'}), 404

        existing = skill_badge_collection.find_one({'_id': participant_id})
        if existing:
            if existing.get('bonus_awarded'):
                return jsonify({'success': False, 'error': 'Badge already earned'}), 409

            attempt_number = existing.get('attempt_number', 0) + 1
            if attempt_number > SKILL_BADGE_MAX_ATTEMPTS:
                return jsonify({'success': False, 'error': 'No retries remaining'}), 409
        else:
            attempt_number = 1

        user_details = user_details_collection.find_one({'_id': participant_id})
        name = participant.get('name', participant_id)
        name_parts = name.split(' ', 1)
        first_name = name_parts[0]
        last_name = name_parts[1] if len(name_parts) > 1 else ''
        email = user_details.get('email', '') if user_details else ''

        scorpion_payload = {
            'examinee_info': {
                'firstName': first_name,
                'lastName': last_name,
                'email': email
            },
            'meta': {
                'assessmentUrl': SCORPION_ASSESSMENT_URL,
                'badgeTemplateId': CREDLY_BADGE_TEMPLATE_ID,
                'callingEnvironment': 'production'
            }
        }

        scorpion_url = f"{SCORPION_BASE_URL}/api/exams/{SCORPION_EXAM_ID}/deliveries"
        scorpion_response = http_requests.post(
            scorpion_url,
            json=scorpion_payload,
            headers={
                'Authorization': SCORPION_API_TOKEN,
                'Content-Type': 'application/json'
            },
            timeout=30
        )

        if not scorpion_response.ok:
            logger.error(f"Scorpion API error: {scorpion_response.status_code} {scorpion_response.text[:300]}")
            return jsonify({
                'success': False,
                'error': f'Scorpion API returned {scorpion_response.status_code}'
            }), 502

        scorpion_data = scorpion_response.json()
        delivery_id = scorpion_data.get('delivery_id', '')
        launch_token = scorpion_data.get('launch_token', '')
        launch_url = f"{SCORPION_BASE_URL}/take?launch_token={launch_token}"

        delivery_doc = {
            '_id': participant_id,
            'delivery_id': delivery_id,
            'examinee_id': scorpion_data.get('examinee_id', ''),
            'launch_token': launch_token,
            'launch_url': launch_url,
            'status': 'created',
            'attempt_number': attempt_number,
            'created_at': datetime.now(timezone.utc).isoformat(),
            'bonus_awarded': False,
            'passed': False,
        }

        skill_badge_collection.replace_one(
            {'_id': participant_id},
            delivery_doc,
            upsert=True
        )

        logger.info(f"Created Scorpion delivery {delivery_id} for {participant_id} (attempt {attempt_number})")
        return jsonify({
            'success': True,
            'launch_url': launch_url,
            'delivery_id': delivery_id,
            'attempt_number': attempt_number
        }), 200

    except Exception as e:
        logger.error(f"Error starting skill badge: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/skill-badge/status/<participant_id>', methods=['GET'])
def get_skill_badge_status(participant_id):
    """Check delivery status by polling Scorpion."""
    if not SKILL_BADGE_ENABLED:
        return jsonify({'enabled': False, 'status': 'not_enabled'}), 200

    try:
        delivery = skill_badge_collection.find_one({'_id': participant_id})
        if not delivery:
            return jsonify({
                'status': 'not_started',
                'bonus_awarded': False,
                'max_attempts': SKILL_BADGE_MAX_ATTEMPTS,
                'attempt_number': 0
            }), 200

        if delivery.get('bonus_awarded'):
            credly_info = delivery.get('credly')
            if not credly_info:
                participant_email = ''
                ud = user_details_collection.find_one({'_id': participant_id})
                if ud:
                    participant_email = ud.get('email', '')
                credly_info = _lookup_credly_badge(participant_email)
                if credly_info:
                    skill_badge_collection.update_one({'_id': participant_id}, {'$set': {'credly': credly_info}})

            return jsonify({
                'status': 'scored',
                'passed': True,
                'score': delivery.get('score'),
                'points_earned': delivery.get('points_earned'),
                'points_available': delivery.get('points_available'),
                'used_seconds': delivery.get('used_seconds'),
                'bonus_awarded': True,
                'attempt_number': delivery.get('attempt_number', 1),
                'max_attempts': SKILL_BADGE_MAX_ATTEMPTS,
                'credly': credly_info,
            }), 200

        delivery_id = delivery.get('delivery_id')
        if not delivery_id:
            return jsonify({'status': delivery.get('status', 'unknown'), 'bonus_awarded': False}), 200

        scorpion_url = f"{SCORPION_BASE_URL}/api/exams/{SCORPION_EXAM_ID}/deliveries/{delivery_id}"
        scorpion_response = http_requests.get(
            scorpion_url,
            headers={'Authorization': SCORPION_API_TOKEN},
            timeout=30
        )

        if not scorpion_response.ok:
            logger.error(f"Scorpion status check error: {scorpion_response.status_code}")
            return jsonify({
                'status': delivery.get('status', 'unknown'),
                'bonus_awarded': False,
                'launch_url': delivery.get('launch_url'),
                'error': 'Failed to check Scorpion status'
            }), 200

        scorpion_data = scorpion_response.json()
        new_status = scorpion_data.get('status', delivery.get('status'))
        passed = scorpion_data.get('passed', False)
        score = scorpion_data.get('score')
        points_earned = scorpion_data.get('points_earned')
        points_available = scorpion_data.get('points_available')
        used_seconds = scorpion_data.get('used_seconds')

        update_fields = {
            'status': new_status,
            'passed': passed,
            'score': score,
            'points_earned': points_earned,
            'points_available': points_available,
            'used_seconds': used_seconds,
        }

        bonus_awarded = False
        if passed and not delivery.get('bonus_awarded'):
            result = skill_badge_collection.find_one_and_update(
                {'_id': participant_id, 'bonus_awarded': {'$ne': True}},
                {'$set': {**update_fields, 'bonus_awarded': True, 'passed_at': datetime.now(timezone.utc).isoformat()}}
            )
            if result is not None:
                results_collection_shared.insert_one({
                    'name': SKILL_BADGE_BONUS_NAME,
                    'username': participant_id,
                    'timestamp': datetime.now(timezone.utc),
                    'points': SKILL_BADGE_BONUS_POINTS,
                })
                bonus_awarded = True
                logger.info(f"Awarded skill badge bonus ({SKILL_BADGE_BONUS_POINTS} pts) to {participant_id}")
        else:
            skill_badge_collection.update_one(
                {'_id': participant_id},
                {'$set': update_fields}
            )
            bonus_awarded = delivery.get('bonus_awarded', False)

        credly_info = None
        if bonus_awarded:
            participant_email = ''
            ud = user_details_collection.find_one({'_id': participant_id})
            if ud:
                participant_email = ud.get('email', '')
            credly_info = _lookup_credly_badge(participant_email)
            if credly_info:
                skill_badge_collection.update_one({'_id': participant_id}, {'$set': {'credly': credly_info}})

        return jsonify({
            'status': new_status,
            'passed': passed,
            'score': score,
            'points_earned': points_earned,
            'points_available': points_available,
            'used_seconds': used_seconds,
            'bonus_awarded': bonus_awarded,
            'attempt_number': delivery.get('attempt_number', 1),
            'max_attempts': SKILL_BADGE_MAX_ATTEMPTS,
            'launch_url': delivery.get('launch_url'),
            'credly': credly_info,
        }), 200

    except Exception as e:
        logger.error(f"Error checking skill badge status: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/skill-badge/statuses', methods=['GET'])
def get_all_skill_badge_statuses():
    """Return badge status for all participants (bulk endpoint for the frontend)."""
    if not SKILL_BADGE_ENABLED:
        return jsonify({'enabled': False, 'statuses': {}}), 200

    try:
        deliveries = list(skill_badge_collection.find({}))
        statuses = {}
        for d in deliveries:
            statuses[d['_id']] = {
                'status': d.get('status', 'unknown'),
                'passed': d.get('passed', False),
                'bonus_awarded': d.get('bonus_awarded', False),
                'attempt_number': d.get('attempt_number', 1),
                'score': d.get('score'),
            }
        badge_meta = _fetch_badge_metadata()
        return jsonify({
            'enabled': True,
            'statuses': statuses,
            'badge_image_url': badge_meta.get('image_url', '') if badge_meta else '',
        }), 200

    except Exception as e:
        logger.error(f"Error fetching skill badge statuses: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_ENV') == 'development'

    logger.info(f"Starting Flask application on port {port}")
    logger.info(f"MongoDB URI: {MONGODB_URI}")
    logger.info(f"Database: {DB_NAME}")
    logger.info(f"Collection: {PARTICIPANTS_COLLECTION}")
    if SKILL_BADGE_ENABLED:
        logger.info(f"Skill Badge: enabled (exam={SCORPION_EXAM_ID}, bonus={SKILL_BADGE_BONUS_POINTS}pts, max_attempts={SKILL_BADGE_MAX_ATTEMPTS})")

    app.run(host='0.0.0.0', port=port, debug=debug)
