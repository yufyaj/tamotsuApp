const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();

exports.handler = async (event) => {
    // リクエストボディからユーザー名とパスワードを取得
    const { username, password } = JSON.parse(event.body);

    // 環境変数からCognito User Pool Client IDを取得
    const clientId = process.env.COGNITO_USER_POOL_CLIENT_ID;

    const params = {
        AuthFlow: 'USER_PASSWORD_AUTH',
        ClientId: clientId,
        AuthParameters: {
            USERNAME: username,
            PASSWORD: password
        }
    };

    try {
        // Cognitoでユーザー認証を実行
        const result = await cognito.initiateAuth(params).promise();
        
        // 認証成功時の処理
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Login successful',
                token: result.AuthenticationResult.IdToken,
                refreshToken: result.AuthenticationResult.RefreshToken
            })
        };
    } catch (error) {
        console.error('Login error:', error);

        // エラーメッセージをカスタマイズ
        let errorMessage = 'An error occurred during login';
        if (error.code === 'NotAuthorizedException') {
            errorMessage = 'Incorrect username or password';
        } else if (error.code === 'UserNotFoundException') {
            errorMessage = 'User does not exist';
        }

        return {
            statusCode: 400,
            body: JSON.stringify({ message: errorMessage })
        };
    }
};
