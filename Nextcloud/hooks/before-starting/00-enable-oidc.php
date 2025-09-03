<?php
$config_file = getenv("CONFIG_FILE");
$provider = getenv("OIDC_PROVIDER_URL");
$client_id = getenv("OIDC_CLIENT_ID");
$client_secret = getenv("OIDC_CLIENT_SECRET");
$logout_url = "www." . getenv("PERSONAL_DOMAIN_NAME");

$config = file_get_contents($config_file);
if ($config === false) { 
    echo "❌ Impossible de lire le fichier config.php\n"; 
    exit(1); 
}

// Supprime ancienne config OIDC si existante
$config = preg_replace("/'oidc_login_.*?' => .*?,\n/s", "", $config);

// Prépare le bloc à insérer
$insert = "
  'oidc_login_provider_url' => '$provider',
  'oidc_login_client_id' => '$client_id',
  'oidc_login_client_secret' => '$client_secret',
  'oidc_login_logout_url' => '$logout_url',
  'oidc_login_auto_redirect' => false,
  'oidc_login_end_session_redirect' => false,
  'oidc_login_button_text' => 'Connexion avec Authelia',
  'oidc_login_scope' => 'openid profile email groups',
  'oidc_login_hide_password_form' => false,
  'oidc_login_use_id_token' => false,
  'oidc_login_attributes' => 
  array (
    'id' => 'name',
    'name' => 'preferred_username',
    'mail' => 'email',
    'groups' => 'groups',
    'is_admin' => 'admin',
  ),
  'oidc_login_allowed_groups' => 
  array (
    0 => 'Cloud',
  ),
  'oidc_login_update_avatar' => true,
  'oidc_login_use_external_storage' => false,
  'oidc_login_proxy_ldap' => false,
  'oidc_login_disable_registration' => false,
  'oidc_login_redir_fallback' => false,
  'oidc_login_tls_verify' => true,
  'oidc_create_groups' => true,
  'oidc_login_password_authentication' => false,
  'oidc_login_code_challenge_method' => 'S256',
";

// Insère juste avant la dernière parenthèse fermante
$config = preg_replace("/\);\s*$/", "$insert);", $config);

// Écrit la config
file_put_contents($config_file, $config);
echo "✅ Config OIDC ajoutée.\n";