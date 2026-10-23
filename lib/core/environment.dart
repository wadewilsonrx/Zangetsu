/// Public Appwrite configuration. These are NOT secrets — the project id and
/// endpoint ship in every Appwrite client app. Auth uses email/password
/// sessions; the server API key is never embedded here.
class Environment {
  static const String appwriteProjectId = '6a1ed44f0029b50bccde';
  static const String appwriteProjectName = 'Zangetsu';
  static const String appwritePublicEndpoint =
      'https://sgp.cloud.appwrite.io/v1';

  // Supabase project URL + anon (public) key — safe to embed, same as the
  // Appwrite project id/endpoint above. Override with --dart-define if a
  // build needs a different project (e.g. staging).
  // NOVAPLAY FORK: no cloud backend — blank defaults keep Supabase
  // uninitialized; main.dart skips initialization when the URL is empty
  // and every store runs local-only.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // NOVAPLAY FORK: the sync client is constructed but never queried while
  // signed out; the default points at the owner's own Worker purely because
  // the boot validator requires a valid HTTPS URL — no upstream endpoint.
  static const String vpsSyncUrl = String.fromEnvironment(
    'VPS_SYNC_URL',
    defaultValue: 'https://nova-catalog.oshadakalindu.workers.dev',
  );

  /// Where Appwrite sends the password-recovery link. Appwrite appends
  /// Password-reset landing. Supabase now drives reset (via the auth `site_url`,
  /// which points at this same page); kept for reference. Not used by the
  /// Supabase AuthCubit, which calls `resetPasswordForEmail`.
  static const String passwordResetUrl = '';

  /// Base of the Zangetsu website (landing + reset + the share "open" page).
  // NOVAPLAY FORK: no upstream website — blank.
  static const String siteBaseUrl = '';

  /// Share links point here. The page opens the app if installed (via the
  /// [openLinkScheme] scheme below), otherwise offers the download. Its domain
  /// must be an Appwrite Web platform (already added for the reset page).
  static const String siteOpenUrl = '$siteBaseUrl/open/';

  /// TV pairing page on the website. Used when someone opens a shared/https
  /// pair link in a browser; the page can hand off to the app via
  /// `zangetsu://pair`. App-facing TV QRs encode the deeplink directly.
  static const String sitePairUrl = '$siteBaseUrl/pair/';

  /// The "open" page redirects to `zangetsu://open?…`; an installed app catches
  /// it (see [OpenLinkService] + the Android manifest intent-filter).
  static const String openLinkScheme = trackerRedirectScheme; // 'zangetsu'
  static const String openLinkHost = 'open';
  static const String pairLinkHost = 'pair';

  // Provisioned backend ids (see docs / setup).
  static const String databaseId = 'main';
  static const String mylistCollectionId = 'mylist';
  static const String historyCollectionId = 'history';
  static const String watchRoomsCollectionId = 'watch_rooms';
  static const String roomParticipantsCollectionId = 'room_participants';
  static const String roomMessagesCollectionId = 'room_messages';
  static const String avatarsBucketId = 'avatars';
  static const String backupsCollectionId = 'backups';

  // ── Tracker OAuth ──────────────────────────────────────────────────────────
  // All redirects share the zangetsu:// scheme; each has its own host with a
  // matching Android intent-filter. Client secrets are embedded where the
  // provider's token exchange requires it (MAL = PKCE, no secret; Simkl needs
  // one) — standard for these APIs and low-risk.
  static const String trackerRedirectScheme = 'zangetsu';

  // AniList — implicit grant (token in URL fragment, 1-year, no secret).
  static const String anilistClientId = '43052';
  static const String anilistRedirectHost = 'anilist-auth';
  static String get anilistRedirectUri =>
      '$trackerRedirectScheme://$anilistRedirectHost';

  // MyAnimeList — OAuth2 PKCE (plain), no client secret.
  static const String malClientId = 'ac006943589381143c4c4e54eac93a89';
  static const String malRedirectHost = 'mal-auth';
  static String get malRedirectUri =>
      '$trackerRedirectScheme://$malRedirectHost';

  // Simkl wants these on EVERY request (url params + a real User-Agent), or
  // the call is invisible in their debug log and they can't help when
  // something breaks. See https://api.simkl.org/conventions/headers.
  static const String simklAppName = 'zangetsu';
  static const String simklApiHost = 'api.simkl.com';
  static const String simklDataHost = 'data.simkl.in';

  // Simkl — OAuth2 authorization-code (needs the secret to exchange the code).
  static const String simklClientId =
      '8b847b09206ccdb0b3de4cc1293d6dd7d355821f5c179c57315da8ba9030eb53';
  static const String simklClientSecret =
      '34ba8e5ac7c8a5c27926dfdf78205e5b913de9928361cb5a243558239298c96d';
  static const String simklRedirectHost = 'simkl-auth';
  static String get simklRedirectUri =>
      '$trackerRedirectScheme://$simklRedirectHost';

  // Back-compat alias (older AniList code referenced this name).
  // ── MangaBaka ────────────────────────────────────────────────────────────
  //
  // Manga/manhwa/manhua only — no anime list, which is why `supportsReading`
  // is the one thing it answers true to.
  //
  // A PUBLIC OAuth client: no secret, PKCE (S256) instead, which is the right
  // shape for an installed app — anything shipped in the APK can be extracted.
  // Endpoints come from https://mangabaka.org/.well-known/openid-configuration
  // (the `.org` host; `api.mangabaka.org/.well-known/*` is 404). MangaBaka's
  // own API docs mention neither OAuth nor tokens, so prefer the discovery
  // document over the docs if they ever disagree.
  static const String mangabakaClientId = 'EkBIEASsBsfRvPKGevUZIcRLSdubVHPK';
  static const String mangabakaRedirectHost = 'mangabaka-auth';
  static String get mangabakaRedirectUri =>
      '$trackerRedirectScheme://$mangabakaRedirectHost';
  static const String mangabakaAuthorizeUrl =
      'https://mangabaka.org/auth/oauth2/authorize';
  static const String mangabakaTokenUrl =
      'https://mangabaka.org/auth/oauth2/token';
  static const String mangabakaRevokeUrl =
      'https://mangabaka.org/auth/oauth2/revoke';
  static const String mangabakaApi = 'https://api.mangabaka.org';

  /// `library.write` is an official scope — third-party writes are supported,
  /// not a workaround. `offline_access` is what returns a refresh token.
  /// `openid` is required by `/v1/my/profile`: with the other four granted it
  /// still answered `BAD_REQUEST: Missing required scope`, which is the OIDC
  /// identity scope missing rather than any library permission.
  static const String mangabakaScopes =
      'openid profile library.read library.write offline_access';

  static const String anilistRedirectScheme = trackerRedirectScheme;
}
