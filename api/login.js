const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();
const dynamoDB = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event, context) => {
  const { email, password } = JSON.parse(event.body);

  try {
    // Cognito User Poolで認証
    const authResponse = await cognito.initiateAuth({
      AuthFlow: 'USER_PASSWORD_AUTH',
      ClientId: process.env.COGNITO_USER_POOL_CLIENT_ID,
      AuthParameters: {
        'USERNAME': email,
        'PASSWORD': password
      }
    }).promise();

    // DynamoDBからユーザー情報を取得
    const user = await dynamoDB.get({
      TableName: process.env.USERS_TABLE,
      Key: {
        'email': email
      }
    }).promise();

    if (!user.Item) {
      return {
        statusCode: 401, // 認証エラー
        body: JSON.stringify({ message: 'ユーザーが見つかりません' })
      };
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ 
        message: 'ログインに成功しました。',
        idToken: authResponse.AuthenticationResult.IdToken, // IDトークンを返す
        user: user.Item // ユーザー情報を返す
      })
    };

  } catch (error) {
    console.error('Error:', error);

    if (error.code === 'NotAuthorizedException') {
      return {
        statusCode: 401, // 認証エラー
        body: JSON.stringify({ message: 'メールアドレスまたはパスワードが間違っています。' })
      };
    } else {
      return {
        statusCode: 500,
        body: JSON.stringify({ message: 'エラーが発生しました。' })
      };
    }
  }
};
