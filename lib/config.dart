/// The one account allowed to change who's captain (see
/// ChangeCaptainScreen and the backend's matching CAPTAIN_CHANGE_OWNER).
/// This is only a client-side convenience to hide the entry point from
/// everyone else — the real enforcement is server-side, checked again on
/// every request regardless of what the client sends.
const kCaptainChangeOwnerId = '428akotilingala@frhsd.com';
