const { successResponse, errorResponse } = require('response-utils');
const { CognitoIdentityProviderClient, InitiateAuthCommand } = require("@aws-sdk/client-cognito-identity-provider");

exports.handler = async (event) => {
    const clientId = process.env.COGNITO_USER_POOL_CLIENT_ID; // CognitoアプリクライアントID
    const region   = process.env.MY_REGION; // AWSリージョン

    console.log('debug_log_0:start');
    console.log('eveht:',event);

    const refreshToken = event.headers['refresh-token'];
    if (!refreshToken) {
        return errorResponse('Refresh token is missing');
    }

    console.log('debug_log_1:checked token');

    const client = new CognitoIdentityProviderClient({ region: region });

    const params = {
        AuthFlow: 'REFRESH_TOKEN_AUTH',
        ClientId: clientId,
        AuthParameters: {
            REFRESH_TOKEN: refreshToken
        }
    };

    const command = new InitiateAuthCommand(params);

    console.log('debug_log_2:initialized command');

    try {
        const response = await client.send(command);
        console.log('debug_log_3:sended command');

        return successResponse({
            accessToken: response.AuthenticationResult.AccessToken,
            refreshToken: response.AuthenticationResult.RefreshToken || refreshToken
        });
    } catch (error) {
        console.error('Failed to refresh tokens:', error);
        return errorResponse('Failed to refresh tokens');
    }
}