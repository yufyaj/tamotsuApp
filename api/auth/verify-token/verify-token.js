const { successResponse, errorResponse } = require('response-utils');
import { CognitoIdentityProviderClient, GetUserCommand } from "@aws-sdk/client-cognito-identity-provider";

exports.handler = async (event) => {
    try{
        const accessToken = event.headers.Authorization.split(' ')[1];

        const region  = process.env.MY_REGION; // AWSリージョン
        const client = new CognitoIdentityProviderClient({ region: region });    

        const getUserCommand           = new GetUserCommand({ AccessToken: accessToken });
        const cognitoUser              = await client.send(getUserCommand);
        const userIdAttribute          = cognitoUser.UserAttributes.find(attr => attr.Name === 'custom:userId').Value;
        const nutritionistIdAttribute  = cognitoUser.UserAttributes.find(attr => attr.Name === 'custom:nutritionistId').Value;

        const userId         = userIdAttribute ? userIdAttribute.Value : null;
        const nutritionistId = nutritionistIdAttribute ? nutritionistIdAttribute.Value : null;

        return successResponse({ result: Boolean(userId || nutritionistId), userType: (userId)?"user":"nutritionist"});
    } catch (error) {
        return errorResponse('トークン検証に失敗しました', 401);
    }
}