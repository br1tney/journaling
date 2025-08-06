import boto3
import json
from datetime import datetime
from flask import current_app

class AWSServices:
    def __init__(self):
        self.dynamodb = boto3.resource('dynamodb')
        self.s3 = boto3.client('s3')
        self.sns = boto3.client('sns')
        
    def save_journal_entry(self, user_id, date, content, images=None):
        table = self.dynamodb.Table('journal-entries')
        entry = {
            'userId': user_id,
            'entryDate': date,
            'content': content,
            'timestamp': datetime.utcnow().isoformat(),
            'images': images or []
        }
        table.put_item(Item=entry)
        return entry
    
    def get_journal_entries(self, user_id, start_date=None, end_date=None):
        table = self.dynamodb.Table('journal-entries')
        # Implementation for querying entries
        
    def track_login(self, user_id, username):
        message = f"User logged in: {username} ({user_id}) at {datetime.utcnow().isoformat()}"
        self.sns.publish(
            TopicArn=current_app.config['SNS_LOGIN_TOPIC'],
            Message=message,
            Subject='DailyTxT Login Notification'
        )
