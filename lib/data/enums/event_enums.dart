enum AppEvent {
  /// NAVIGATION EVENTS
  navigatedTo("NAVIGATED TO"),

  /// BROWSER EVENTS
  openedLink("OPENED LINK"),

  /// SESSION EVENTS
  loggedIn("LOGGED IN"),
  loggedOut("LOGGED OUT"),

  /// SWITCH EVENTS
  switchedTheme("SWITCHED THEME"),
  switchedLanguage("SWITCHED LANGUAGE"),

  /// CREATE EVERNTS
  createdccount("CREATED NEW ACCOUNT"),

  /// TOOGLE EVENTS
  toggleRememberMe("CLICKED REMEMEMBER ME BUTTON"),

  /// SELECT EVENTS
  selectedAudioFIle("SELECTED AUDIO FROM DISK"),
  selectedDocumentFile("SELECTED DOCUMENT FROM DISK"),

  /// UPDATE EVENTS
  updatedProfile("UPDATED PROFILE"),

  /// CLICK EVENTS
  clickedBtn("CLICKED BUTTON"),
  clickedBackBtn("CLICKED BACK BUTTON"),
  clickedCloseBtn("CLICKED CLOSE BUTTON"),

  /// NETWORK EVENTS
  apiRequest("API REQUEST");

  const AppEvent(this.name);

  final String name;

  String get value => name;
}
