import 'package:equatable/equatable.dart';

/// {@category Data}
/// Defines tracked events for the application's analytics engine.
///
/// Refactored from a closed enum to an extensible class, allowing host apps to instantiate
/// custom events (`AppEvent('custom_event_name')`) while providing predefined static constants.
class AppEvent extends Equatable {
  /// The underlying string identifier of the event.
  final String name;

  /// Creates a new [AppEvent] with the specified [name].
  const AppEvent(this.name);

  /// Returns the string representation of the event name.
  String get value => name;

  @override
  List<Object?> get props => [name];

  @override
  String toString() => name;

  // ==========================================
  // NAVIGATION & SYSTEM EVENTS
  // ==========================================
  static const AppEvent navigatedTo = AppEvent("NAVIGATED TO");
  static const AppEvent openedLink = AppEvent("OPENED LINK");

  // ==========================================
  // SESSION & AUTH EVENTS
  // ==========================================
  static const AppEvent loggedIn = AppEvent("LOGGED IN");
  static const AppEvent loggedOut = AppEvent("LOGGED OUT");
  static const AppEvent sessionTimeout = AppEvent("SESSION TIMEOUT");
  static const AppEvent biometricsEnabled = AppEvent("BIOMETRICS ENABLED");
  static const AppEvent biometricsDisabled = AppEvent("BIOMETRICS DISABLED");
  static const AppEvent passwordChanged = AppEvent("PASSWORD CHANGED");
  static const AppEvent pinChanged = AppEvent("PIN CHANGED");
  static const AppEvent deviceRegistered = AppEvent("DEVICE REGISTERED");
  static const AppEvent deviceDeregistered = AppEvent("DEVICE DEREGISTERED");

  // ==========================================
  // PREFERENCES & SETTINGS EVENTS
  // ==========================================
  static const AppEvent switchedTheme = AppEvent("SWITCHED THEME");
  static const AppEvent switchedLanguage = AppEvent("SWITCHED LANGUAGE");
  static const AppEvent toggleRememberMe = AppEvent(
    "CLICKED REMEMBER ME BUTTON",
  );

  // ==========================================
  // ACCOUNT MANAGEMENT EVENTS
  // ==========================================
  static const AppEvent createdAccount = AppEvent("CREATED NEW ACCOUNT");
  static const AppEvent updatedProfile = AppEvent("UPDATED PROFILE");
  static const AppEvent accountStatementRequested = AppEvent(
    "ACCOUNT STATEMENT REQUESTED",
  );
  static const AppEvent accountStatementDownloaded = AppEvent(
    "ACCOUNT STATEMENT DOWNLOADED",
  );

  // ==========================================
  // TRANSFER & PAYMENT EVENTS
  // ==========================================
  static const AppEvent transferInitiated = AppEvent("TRANSFER INITIATED");
  static const AppEvent transferCompleted = AppEvent("TRANSFER COMPLETED");
  static const AppEvent transferFailed = AppEvent("TRANSFER FAILED");
  static const AppEvent bulkTransferInitiated = AppEvent(
    "BULK TRANSFER INITIATED",
  );
  static const AppEvent bulkTransferCompleted = AppEvent(
    "BULK TRANSFER COMPLETED",
  );
  static const AppEvent bulkTransferFailed = AppEvent("BULK TRANSFER FAILED");
  static const AppEvent billPaymentInitiated = AppEvent(
    "BILL PAYMENT INITIATED",
  );
  static const AppEvent billPaymentCompleted = AppEvent(
    "BILL PAYMENT COMPLETED",
  );
  static const AppEvent billPaymentFailed = AppEvent("BILL PAYMENT FAILED");
  static const AppEvent airtimePurchaseInitiated = AppEvent(
    "AIRTIME PURCHASE INITIATED",
  );
  static const AppEvent airtimePurchaseCompleted = AppEvent(
    "AIRTIME PURCHASE COMPLETED",
  );
  static const AppEvent airtimePurchaseFailed = AppEvent(
    "AIRTIME PURCHASE FAILED",
  );

  // ==========================================
  // BENEFICIARY MANAGEMENT EVENTS
  // ==========================================
  static const AppEvent beneficiaryAdded = AppEvent("BENEFICIARY ADDED");
  static const AppEvent beneficiaryEdited = AppEvent("BENEFICIARY EDITED");
  static const AppEvent beneficiaryDeleted = AppEvent("BENEFICIARY DELETED");

  // ==========================================
  // CARD MANAGEMENT EVENTS
  // ==========================================
  static const AppEvent cardRequested = AppEvent("CARD REQUESTED");
  static const AppEvent cardActivated = AppEvent("CARD ACTIVATED");
  static const AppEvent cardBlocked = AppEvent("CARD BLOCKED");
  static const AppEvent cardUnblocked = AppEvent("CARD UNBLOCKED");
  static const AppEvent cardPinChanged = AppEvent("CARD PIN CHANGED");
  static const AppEvent cardLimitsUpdated = AppEvent("CARD LIMITS UPDATED");

  // ==========================================
  // LOAN MANAGEMENT EVENTS
  // ==========================================
  static const AppEvent loanRequested = AppEvent("LOAN REQUESTED");
  static const AppEvent loanRepaid = AppEvent("LOAN REPAID");

  // ==========================================
  // BUSINESS BANKING EVENTS
  // ==========================================
  static const AppEvent invoiceCreated = AppEvent("INVOICE CREATED");
  static const AppEvent payrollProcessed = AppEvent("PAYROLL PROCESSED");
  static const AppEvent transactionApproved = AppEvent("TRANSACTION APPROVED");
  static const AppEvent transactionRejected = AppEvent("TRANSACTION REJECTED");
  static const AppEvent transactionPendingApproval = AppEvent(
    "TRANSACTION PENDING APPROVAL",
  );

  // ==========================================
  // KYC & VERIFICATION EVENTS
  // ==========================================
  static const AppEvent kycStarted = AppEvent("KYC STARTED");
  static const AppEvent kycCompleted = AppEvent("KYC COMPLETED");
  static const AppEvent kycFailed = AppEvent("KYC FAILED");
  static const AppEvent livenessCheckInitiated = AppEvent(
    "LIVENESS CHECK INITIATED",
  );
  static const AppEvent livenessCheckCompleted = AppEvent(
    "LIVENESS CHECK COMPLETED",
  );

  // ==========================================
  // DOCUMENT SUBMISSION EVENTS
  // ==========================================
  static const AppEvent documentSubmitted = AppEvent("DOCUMENT SUBMITTED");
  static const AppEvent documentVerified = AppEvent("DOCUMENT VERIFIED");
  static const AppEvent documentRejected = AppEvent("DOCUMENT REJECTED");

  // ==========================================
  // LEARNING & LESSON EVENTS
  // ==========================================
  static const AppEvent lessonStarted = AppEvent("LESSON STARTED");
  static const AppEvent lessonCompleted = AppEvent("LESSON COMPLETED");
  static const AppEvent lessonPaused = AppEvent("LESSON PAUSED");

  // ==========================================
  // CUSTOMER SUPPORT EVENTS
  // ==========================================
  static const AppEvent liveChatInitiated = AppEvent("LIVE CHAT INITIATED");
  static const AppEvent supportTicketCreated = AppEvent(
    "SUPPORT TICKET CREATED",
  );
  static const AppEvent faqViewed = AppEvent("FAQ VIEWED");

  // ==========================================
  // FILE SELECTION EVENTS
  // ==========================================
  static const AppEvent selectedAudioFile = AppEvent(
    "SELECTED AUDIO FROM DISK",
  );
  static const AppEvent selectedVideoFile = AppEvent(
    "SELECTED VIDEO FROM DISK",
  );
  static const AppEvent selectedDocumentFile = AppEvent(
    "SELECTED DOCUMENT FROM DISK",
  );
  static const AppEvent selectedImageFile = AppEvent(
    "SELECTED IMAGE FROM DISK",
  );

  // ==========================================
  // CLICK EVENTS
  // ==========================================
  static const AppEvent clickedBtn = AppEvent("CLICKED BUTTON");
  static const AppEvent clickedBackBtn = AppEvent("CLICKED BACK BUTTON");
  static const AppEvent clickedCloseBtn = AppEvent("CLICKED CLOSE BUTTON");

  // ==========================================
  // NETWORK EVENTS
  // ==========================================
  static const AppEvent apiRequest = AppEvent("API REQUEST");
  static const AppEvent apiResponse = AppEvent("API RESPONSE");
  static const AppEvent apiError = AppEvent("API ERROR");

  // ==========================================
  // ONBOARDING EVENTS (PDF SPECIFICATION)
  // ==========================================
  static const AppEvent newUserConfirmPhoneNumber = AppEvent(
    "NewUser_cofirmPhonenumber",
  );
  static const AppEvent newUserInputOTP = AppEvent("NewUser_InputOTP");
  static const AppEvent newUserPersonalDetails = AppEvent(
    "NewUser_PersonalDetails",
  );
  static const AppEvent newUserBVNStarted = AppEvent("NewUser_BVN_Started");
  static const AppEvent newUserFacialCapture = AppEvent(
    "NewUser_FacialCapture",
  );
  static const AppEvent newUserInputNIN = AppEvent("NewUser_inputNIN");
  static const AppEvent newUserUploadSignature = AppEvent(
    "NewUser_uploadSignature",
  );
  static const AppEvent newUserReferenceSubmitted = AppEvent(
    "NewUser_ReferenceSubmitted",
  );
  static const AppEvent newUserInputPasscode = AppEvent(
    "NewUser_InputPasscode",
  );
  static const AppEvent newUserPEPSignupSuccessful = AppEvent(
    "NewUser_PEP_SignupSuccessful",
  );

  // ==========================================
  // CARDS EVENTS (PDF SPECIFICATION)
  // ==========================================
  static const AppEvent userPhysicalCard = AppEvent("User_PhysicalCard");
  static const AppEvent userSelectAccount = AppEvent("User_selectAccount");
  static const AppEvent userSelectCardType = AppEvent("User_selectCardType");
  static const AppEvent userCardRequestSuccessful = AppEvent(
    "User_CardRequest_Successful",
  );

  // ==========================================
  // BILLS & INTERNET EVENTS (PDF SPECIFICATION)
  // ==========================================
  static const AppEvent userBillsInternetStart = AppEvent(
    "user_Bills_Internet_Start",
  );
  static const AppEvent userBillsInternetProviderSelected = AppEvent(
    "user_Bills_Internet_ProviderSelected",
  );
  static const AppEvent userBillsInternetFrequencySelected = AppEvent(
    "user_Bills_Internet_FrequencySelected",
  );
  static const AppEvent userBillsInternetPackageSelected = AppEvent(
    "user_Bills_Internet_PackageSelected",
  );
  static const AppEvent userBillsInternetReviewedSummary = AppEvent(
    "user_Bills_Internet_ReviewedSummary",
  );
  static const AppEvent userBillsInternetSuccessful = AppEvent(
    "user_Bills_Internet_Successful",
  );

  // ==========================================
  // AIRTIME EVENTS (PDF SPECIFICATION)
  // ==========================================
  static const AppEvent userBillsAirtimeStart = AppEvent(
    "user_Bills_Airtime_Start",
  );
  static const AppEvent userBillsAirtimeNumberEntered = AppEvent(
    "user_Bills_Airtime_NumberEntered",
  );
  static const AppEvent userBillsAirtimeAmountEntered = AppEvent(
    "user_Bills_Airtime_AmountEntered",
  );
  static const AppEvent userBillsAirtimeReviewedSummary = AppEvent(
    "user_Bills_Airtime_ReviewedSummary",
  );
  static const AppEvent userBillsAirtimeSuccessful = AppEvent(
    "user_Bills_Airtime_Successful",
  );
  static const AppEvent userBillsAirtimeFailed = AppEvent(
    "user_Bills_Airtime_Failed",
  );

  // ==========================================
  // TRANSFER EVENTS (PDF SPECIFICATION)
  // ==========================================
  static const AppEvent userTransferStart = AppEvent("user_Transfer_Start");
  static const AppEvent userTransferBeneficiarySelected = AppEvent(
    "user_Transfer_BeneficiarySelected",
  );
  static const AppEvent userTransferBankSelected = AppEvent(
    "user_Transfer_BankSelected",
  );
  static const AppEvent userTransferAmountEntered = AppEvent(
    "user_Transfer_AmountEntered",
  );
  static const AppEvent userTransferReviewedSummary = AppEvent(
    "user_Transfer_ReviewedSummary",
  );
  static const AppEvent userTransferSuccessful = AppEvent(
    "user_Transfer_Successful",
  );
  static const AppEvent userTransferFailed = AppEvent("user_Transfer_Failed");

  // ==========================================
  // FX SWAP EVENTS (PDF SPECIFICATION)
  // ==========================================
  static const AppEvent userFXSwapStart = AppEvent("user_FXSwap_Start");
  static const AppEvent userFXSwapAmountEntered = AppEvent(
    "user_FXSwap_AmountEntered",
  );
  static const AppEvent userFXSwapReviewedSummary = AppEvent(
    "user_FXSwap_ReviewedSummary",
  );
  static const AppEvent userFXSwapSuccessful = AppEvent(
    "user_FXSwap_Successful",
  );
  static const AppEvent userFXSwapFailed = AppEvent("user_FXSwap_Failed");
}

/// {@category Data}
/// Represents a structured analytics event containing an [event] type,
/// [description], execution timestamp, and optional [value].
class AppAnalyticsData {
  final AppEvent event;
  final String? description;
  final DateTime executedAt;
  final dynamic value;

  /// How long the tracked operation took, for events that measure one.
  ///
  /// Emitted as the numeric `durationMs` parameter so it can be aggregated
  /// (p50/p95/p99) rather than only read one event at a time.
  final Duration? duration;

  /// Named sub-durations in milliseconds, for events built from several
  /// phases — a request's `renew`, `encrypt` or `decrypt` legs, for example.
  final Map<String, int>? phases;

  AppAnalyticsData(
    this.event, {
    this.description,
    this.value,
    this.duration,
    this.phases,
  }) : executedAt = DateTime.now();

  Map<String, Object> toJson() {
    final data = <String, Object>{
      "description": description ?? event.name,
      "value": "$value",
      "executedAt": executedAt.millisecondsSinceEpoch,
      if (duration case final elapsed?) "durationMs": elapsed.inMilliseconds,
      ...?phases?.map((phase, ms) => MapEntry("${phase}Ms", ms)),
    };
    return data;
  }
}
