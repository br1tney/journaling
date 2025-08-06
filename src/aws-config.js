import { Amplify } from 'aws-amplify';

const awsConfig = {
  Auth: {
    region: 'us-east-1', 
    userPoolId: 'YOUR_USER_POOL_ID',
    userPoolWebClientId: 'YOUR_CLIENT_ID',
    identityPoolId: 'YOUR_IDENTITY_POOL_ID'
  },
  Storage: {
    AWSS3: {
      bucket: 'dailytxt-images-[suffix]',
      region: 'us-east-1'
    }
  },
  API: {
    endpoints: [
      {
        name: "dailytxt-api",
        endpoint: "https://your-api-gateway-url",
        region: 'us-east-1'
      }
    ]
  }
};

Amplify.configure(awsConfig);
