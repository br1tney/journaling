import { withAuthenticator } from '@aws-amplify/ui-react';
import { useEffect } from 'react';
import { Auth } from 'aws-amplify';
import { SNS } from 'aws-sdk';

function AuthWrapper({ children, user }) {
  useEffect(() => {
    if (user) {
      // Track login with SNS
      trackLogin(user);
    }
  }, [user]);

  const trackLogin = async (user) => {
    try {
      const sns = new SNS({
        region: 'us-east-1',
        credentials: await Auth.currentCredentials()
      });
      
      await sns.publish({
        TopicArn: 'arn:aws:sns:REGION:ACCOUNT:dailytxt-login-notifications',
        Message: `User logged in: ${user.username} at ${new Date().toISOString()}`,
        Subject: 'DailyTxT Login Notification'
      }).promise();
    } catch (error) {
      console.error('Error tracking login:', error);
    }
  };

  return <div>{children}</div>;
}

export default withAuthenticator(AuthWrapper);
