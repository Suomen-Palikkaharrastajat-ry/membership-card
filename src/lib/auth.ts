import { UserManager } from 'oidc-client-ts';
import { browser } from '$app/environment';

// Configuration - read from environment variables
const authority =
	import.meta.env.OIDC_AUTHORITY ||
	'https://lemur-14.cloud-iam.com/auth/realms/suomenpalikkaharrastajatry';
const client_id = import.meta.env.OIDC_CLIENT_ID || 'd31f9cee-fbe6-4672-8085-76500eb25691';
const redirect_uri =
	import.meta.env.OIDC_REDIRECT_URI ||
	(browser ? `${window.location.origin}/callback` : 'http://localhost:5173/callback');

const userManager = new UserManager({
	authority,
	client_id,
	redirect_uri,
	response_type: 'code',
	scope: 'openid profile email',
	automaticSilentRenew: true
});

export const login = () => {
	return userManager.signinRedirect();
};

export const logout = () => {
	return userManager.signoutRedirect();
};

export const getUser = () => {
	return userManager.getUser();
};

export const completeLogin = () => {
	return userManager.signinCallback();
};
