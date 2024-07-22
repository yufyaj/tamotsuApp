const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();

exports.handler = async (event) => {
    const { username, email, password } = JSON.parse(event.body);
    const clientId = process.env.COGNITO_USER_POOL_CLIENT_ID;

    const params = {
        ClientId: clientId,
        Username: username,
        Password: password,
        UserAttributes: [
            {
                Name: 'email',
                Value: email
            }
        ]
    };

    try {
        const result = await cognito.signUp(params).promise();
        console.log('User signed up successfully:', result);

        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'User signed up successfully', userSub: result.UserSub })
        };
    } catch (error) {
        console.error('Error signing up user:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Error signing up user', error: error.message })
        };
    }
};
