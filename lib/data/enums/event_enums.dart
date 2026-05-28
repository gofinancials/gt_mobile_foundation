/// {@category Data}
/// Defines the specific events tracked by the application's analytics engine.
enum AppEvent {
  /// NAVIGATION EVENTS
  navigatedTo("NAVIGATED TO"),

  /// BROWSER EVENTS
  openedLink("OPENED LINK"),

  /// SESSION & AUTH EVENTS
  loggedIn("LOGGED IN"),
  loggedOut("LOGGED OUT"),
  sessionTimeout("SESSION TIMEOUT"),
  biometricsEnabled("BIOMETRICS ENABLED"),
  biometricsDisabled("BIOMETRICS DISABLED"),
  passwordChanged("PASSWORD CHANGED"),
  pinChanged("PIN CHANGED"),
  deviceRegistered("DEVICE REGISTERED"),
  deviceDeregistered("DEVICE DEREGISTERED"),

  /// PREFERENCES & SETTINGS EVENTS
  switchedTheme("SWITCHED THEME"),
  switchedLanguage("SWITCHED LANGUAGE"),
  toggleRememberMe("CLICKED REMEMBER ME BUTTON"),

  /// ACCOUNT MANAGEMENT EVENTS
  createdAccount("CREATED NEW ACCOUNT"),
  updatedProfile("UPDATED PROFILE"),
  accountStatementRequested("ACCOUNT STATEMENT REQUESTED"),
  accountStatementDownloaded("ACCOUNT STATEMENT DOWNLOADED"),

  /// TRANSFER & PAYMENT EVENTS
  transferInitiated("TRANSFER INITIATED"),
  transferCompleted("TRANSFER COMPLETED"),
  transferFailed("TRANSFER FAILED"),
  bulkTransferInitiated("BULK TRANSFER INITIATED"),
  bulkTransferCompleted("BULK TRANSFER COMPLETED"),
  bulkTransferFailed("BULK TRANSFER FAILED"),
  billPaymentInitiated("BILL PAYMENT INITIATED"),
  billPaymentCompleted("BILL PAYMENT COMPLETED"),
  billPaymentFailed("BILL PAYMENT FAILED"),
  airtimePurchaseInitiated("AIRTIME PURCHASE INITIATED"),
  airtimePurchaseCompleted("AIRTIME PURCHASE COMPLETED"),
  airtimePurchaseFailed("AIRTIME PURCHASE FAILED"),

  /// BENEFICIARY MANAGEMENT EVENTS
  beneficiaryAdded("BENEFICIARY ADDED"),
  beneficiaryEdited("BENEFICIARY EDITED"),
  beneficiaryDeleted("BENEFICIARY DELETED"),

  /// CARD MANAGEMENT EVENTS
  cardRequested("CARD REQUESTED"),
  cardActivated("CARD ACTIVATED"),
  cardBlocked("CARD BLOCKED"),
  cardUnblocked("CARD UNBLOCKED"),
  cardPinChanged("CARD PIN CHANGED"),
  cardLimitsUpdated("CARD LIMITS UPDATED"),

  /// LOAN MANAGEMENT EVENTS
  loanRequested("LOAN REQUESTED"),
  loanRepaid("LOAN REPAID"),

  /// BUSINESS BANKING EVENTS
  invoiceCreated("INVOICE CREATED"),
  payrollProcessed("PAYROLL PROCESSED"),
  transactionApproved("TRANSACTION APPROVED"),
  transactionRejected("TRANSACTION REJECTED"),
  transactionPendingApproval("TRANSACTION PENDING APPROVAL"),

  /// KYC & VERIFICATION EVENTS
  kycStarted("KYC STARTED"),
  kycCompleted("KYC COMPLETED"),
  kycFailed("KYC FAILED"),
  livenessCheckInitiated("LIVENESS CHECK INITIATED"),
  livenessCheckCompleted("LIVENESS CHECK COMPLETED"),

  /// DOCUMENT SUBMISSION EVENTS
  documentSubmitted("DOCUMENT SUBMITTED"),
  documentVerified("DOCUMENT VERIFIED"),
  documentRejected("DOCUMENT REJECTED"),

  /// LEARNING & LESSON EVENTS
  lessonStarted("LESSON STARTED"),
  lessonCompleted("LESSON COMPLETED"),
  lessonPaused("LESSON PAUSED"),

  /// CUSTOMER SUPPORT EVENTS
  liveChatInitiated("LIVE CHAT INITIATED"),
  supportTicketCreated("SUPPORT TICKET CREATED"),
  faqViewed("FAQ VIEWED"),

  /// FILE SELECTION EVENTS
  selectedAudioFile("SELECTED AUDIO FROM DISK"),
  selectedVideoFile("SELECTED VIDEO FROM DISK"),
  selectedDocumentFile("SELECTED DOCUMENT FROM DISK"),
  selectedImageFile("SELECTED IMAGE FROM DISK"),

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
