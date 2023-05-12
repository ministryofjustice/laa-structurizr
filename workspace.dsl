workspace "LAA digital" {

    model {
        properties {
          "structurizr.groupSeparator" "/"
        }

        provider = person "Legal Aid provider"
        citizen = person "Citizen" "A member of the public in England or Wales"
        criminalCaseworker = person "Criminal caseworker" "A caseworker who manages applications for criminal legal aid"
        civilMeansCaseworker = person "Civil means caseworker" "A caseworker who assesses civil legal aid applications for means"
        civilMeritsCaseworker = person "Civil merits caseworker" "A caseworker who assesses civil legal aid applications for merits"
        billingCaseworker = person "Billing caseworker" "A caseworker who verifies legal aid provider's bills"
        directServicesTeam = person "Direct Services Team" "Maintains the Civil Legal Aid operator relationship and performance"
        contactCentreOperator = person "Contact Centre Operator" "Contact centre personel who signposts members of the public in their legal help queries"

        group "LAA Digital" {
          group "Civil applications and billing" {
            ccms = softwareSystem "CCMS" "Legal aid applications, case management, financials, billing, and more" {
              providerDetailsApi = container "Provider Details API" "An XML API to provide reference data required to integrate with CCMS services"
              pui = container "Provider User Interface" "Service for providers to submit civil legal aid applications and billing claims"
              tds = container "Temporary Data Store" "Stores in-progress applications"
              soa = container "SOA" "A SOAP API to E-Business Suite"
              ebs = container "EBS" "Customised E-Business Suite"
              ccmsDb = container "Oracle DB"
              oracleForms = container "Oracle Forms" "Forms that provide a UI for interacting with the EBS database"
              opa = container "OPA" "Dynamically generates interview questions based on business rules"
              meansMeritsConnector = container "Means and merits connector" "Web Determinations data adaptor plugin"
              formsConnector = container "Forms connector" "Web Determinations data adaptor plugin that emails form submissions to inboxes"

              providerDetailsAPI -> ccmsDb "Connect to"
              ebs -> ccmsDb "Connects to"
              soa -> ccmsDb "Connects to"
              meansMeritsConnector -> tds "Reads and writes data to"
              opa -> meansMeritsConnector "Reads and writes applications to"
              opa -> formsConnector "Sends completed feedback, and fraud forms for emailing"
              pui -> tds "Reads and writes data to"
              pui -> soa "Reads and writes applications to [SOAP]"
              pui -> opa "Serves forms [SOAP]"
              oracleForms -> ccmsDb "Reads and writes data to"
              tds -> ebs "Reads data from"
            }

            apply = softwareSystem "Civil Apply" "Web service for providers and legal aid applicants to apply for legal aid" {
              applyApp = container "Apply" "Ruby on Rails app"
              applyDb = container "Apply DB" "Postgres database"
              applySidekiq = container "Sidekiq" "Listens to queued events and processes them"
              applyQueue = container "Queue" "Key-value store used for scheduling jobs via Sidekiq"
              applyClamAV = container "Clam AV" "Clam AntiVirus virus scanner"
              lfa = container "Legal Framework API" "A service for checking means and merits requirements for civil legal aid applications"

              applyApp -> applyDb "Connects to"
              applySidekiq -> applyQueue "Processes queued jobs from"
              applyApp -> applyQueue "Queues feedback jobs to"
              applyApp -> applyClamAV "Scans attachments with"
            }

            cis = softwareSystem "CIS" "CIS is a legacy system that has been largely superseded but still performs invoicing and caseworking for specific cases" {
              cisDb = container "CIS DB" "Oracle Database"
            }
          }

          
          group "Civil help" {
            cla = softwareSystem "CLA" "Web service provided to the general public in England and Wales where users can obtain free legal advice from specialist legal providers relating to a range of Civil matters"
            fala = softwareSystem "Find a Legal Advisor (FALA)" "Web service used to search for a legal adviser or family mediator with a legal aid contract in England and Wales."
            laalaa = softwareSystem "Legal Aid Agency Legal Adviser API (LAALAA)" "API for looking up legal advisers, backed by a Postgres database."
          }

          group "Eligibility" {
            cfe = softwareSystem "CFE" "A service for checking financial eligibility for legal aid"
            benefitChecker = softwareSystem "Benefit Checker" "An interface to the DWP, providing access to the benefit entitlement of applicants"
            hmrcInterface = softwareSystem "HMRC Interface" "An interface between the LAA and HMRC providing access to income, fraud and debt data"
          }

          group "Providers and identity" {
            portal = softwareSystem "LAA Online Portal" "Single sign on for the LAA"
            cwa = softwareSystem "CWA" "CWA is a billing system that contains all provider contracts and schedules" {
              cwaEbs = container "EBS" "Oracle EBS 11i application"
              cwaDb = container "CWA DB" "Oracle database"

              cwaEbs -> cwaDb "Connects to"
            }
            azure = softwareSystem "MOJ AzureAD" "MOJ instance of AzureAd"
          }


          group "OS Places" {
            postcodeapi = softwareSystem "Ordnance survey Postcodes lookup API"
          }

          1 = group "Criminal applications" {
            maat = softwareSystem "MAAT" "System used to assess criminal legal aid applications" {
              maatApp = container "MAAT" "Java app"
              maatDb = container "MAAT DB" "An Oracle Database storing case information from HMCTS and decisions regarding Legal Aid Applications"
              maatApi = container "MAAT API" "An API providing an interface to the MAAT DB"

              maatApp -> maatDb "Connects to"
              maatApi -> maatDb "Accesses and stores Court information"
            }
            eforms = softwareSystem "EForms" "Electronic form submission. Historical paper forms digitised and made available to legal providers. Includes applying for and billing for types of criminal legal aid."
            nolasa = softwareSystem "NoLASA" "Is a micro-service that reads cases that have been marked as 'not-on-libra' from the MLRA database once a day and auto-searches the HMCTS Libra system"
            infox = softwareSystem "InfoX" "Adaptor to the HMCTS Libra system"
            mlra = softwareSystem "MLRA" "System provides an interface to HMCTS' Libra system that contains data about magistrates court cases, also manages representation orders for criminal legal aid"
            cda = softwareSystem "CDA" "Adaptor to the HMCTS Common Platform" {
              cdaSqs = container "CDA SQS" "Used for pushing notifications from HMCTS to other LAA systems"
              cdaApi = container "CDA" "Ruby on Rails API to allow LAA access Common Platform data"
              cdaDb = container "CDA DB" "Postgres DB stores OAuth credentials, metadata and acts a cache for some Common Platform data"

              cdaApi -> cdaDb "Connects to"
              cdaApi -> cdaSqs "Adds events to process by other systems"
            }

            eforms -> maatDb "Submits applications for criminal legal aid [HUB]"
            maatDb -> eforms "Sends legal aid decisions and status updates [HUB]"

            crimeApply = softwareSystem "Crime Apply" "Web service for providers to apply for criminal legal aid on behalf of clients" {
              crimeApplyApp = container "Crime Apply" "Ruby on Rails application"
              crimeApplyDb = container "Crime Apply DB" "Postgres"
            }

            crimeReview = softwareSystem "Crime Review" "Web service for caseworkers to review applications for criminal legal aid" {
              crimeReviewApp = container "Crime Review" "Ruby on Rails application"
              crimeReviewDb = container "Crime Review DB" "Postgres"
            }

            crimeDatastore = softwareSystem "Criminal Applications datastore" "Data service for storing submitted criminal legal aid applications" {
              crimeDatastoreApi = container "API" "Ruby on Rails application"
              crimeDatastoreDb = container "Datastore DB" "Postgres"
            }
                crimeApplyApp -> crimeApplyDb "Connects to"
                crimeReviewApp -> crimeReviewDb "Connects to"
             
            crimeApplyApp -> crimeDatastoreApi "Submits applications for criminal legal aid"
            crimeReviewApp -> crimeDatastoreApi "Fetches applications for criminal legal aid"
            crimeDatastoreApi -> crimeDatastoreDb "Connects to"
            maatApi -> crimeDatastoreApi "Fetches applications for criminal legal aid"
          }


          group "Criminal billing" {
            ccr = softwareSystem "CCR" "Web service that manages advocate fee claims" {
              ccrApp = container "CCR" "Java app"
              ccrDb = container "DB" "Oracle database"

              ccrApp -> ccrDb "Connects to"
            }
            cclf = softwareSystem "CCLF" "Web service that manages litigators fee claims" {
              cclfApp = container "CCLF" "Java app"
              cclfDb = container "DB" "Oracle database"

              cclfApp -> cclfDb "Connects to"
            }
            cccd = softwareSystem "CCCD" "Claim for Crown Court Defence - service for the remunerating of advocates and litigators by the Legal Aid Agency for work done on behalf of defendants in criminal proceedings." {
              cccdApp = container "CCCD" "Ruby on Rails app"
              cccdDb = container "CCCD DB" "Postgres database"
              cccdSidekiq = container "Sidekiq" "Listens to queued events and processes them"
              cccdRedis = container "Redis" "In memory data store"
              ccrSqs = container "CCR SQS" "AWS SQS queue"
              cclfSqs = container "CCLF SQS" "AWS SQS queue"
              cccdSns = container "SNS" "AWS SNS topic"
              cccdApi = container "API"
              cccdSqs = container "Process response SQS" "AWS SQS queue"

              cccdApp -> cccdDb "Connects to"
              cccdApp -> cccdRedis "Caches API calls, queues jobs to"
              cccdApp -> cccdSns "Pushes claim when received"
              cccdSidekiq -> cccdRedis "Processes queued jobs from"
              cccdSns -> ccrSqs "Queues job for CCR to process claim"
              cccdSns -> cclfSqs "Queues job for CCLF to process claim"
              cccdApp -> cccdSqs "Processes job to see if claim is successful or not"
            }
            vcd = softwareSystem "VCD" "View Court Data - The laa-court-data-ui system is a web service that Application and Billing case workers use to view data from court systems"
            feeCalculator = softwareSystem "Fee Calculator" "A system that keeps track of Fee Schemes and provides an API to query this large dataset"

            cccdApp -> feeCalculator "Uses API to calculate fees"
            cclfApp -> cccdApp "Gets Claims information from and sends claim decision"
            cclfApp -> cclfSqs "Processes job to know to pull claim information"
            cclfApp -> cccdSqs "Notifies CCCD of success/failure of claim"
            cclfApp -> cccdApi "Pulls claim from"
            ccrApp -> cccdApp "Gets Claims information from and sends claim decision"
            ccrApp -> cclfSqs "Processes job to know to pull claim information"
            ccrApp -> cccdSqs "Notifies CCCD of success/failure of claim"
            ccrApp -> cccdApi "Pulls claim from"
            vcd -> cdaApi "Calls to fetch court data from HMCTS Common Platform"
          }

          group "Data" {
            eric = softwareSystem "ERIC" "Provides financial reporting based on MI"
            edw = softwareSystem "EDW" "Data warehouse for MI"

            edw -> eric "Pushes financial data from CWA, CIS, CCMS"
          }
        }

        geckoboard = softwareSystem "Geckoboard" {
          tags "External"
        }

        osPlaces = softwareSystem "OS Places API" {
          tags "External"
        }

        bankHolidaysApi = softwareSystem "Bank Holidays API" {
          tags "External"
        }

        group "Government" {
          dwp = softwareSystem "DWP" {
            tags "External"
          }
          hmrc = softwareSystem "HMRC" {
            tags "External"
          }
          notify = softwareSystem "Gov Notify" {
            tags "External"
          }

          group "HMCTS" {
            libra = softwareSystem "Libra" "Magistrates court system run by HMCTS" {
              tags "External"
            }
            xhibit = softwareSystem "Xhibit" "Crown court system run by HMCTS" {
              tags "External"
            }
            commonPlatform = softwareSystem "Common Platform" "Court system covering both magistrates and crown courts, replacing Libra and Xhibit" {
              tags "External"
            }
          }
        }

        group "Banking" {
          trueLayer = softwareSystem "TrueLayer" {
            tags "External"
          }
          allPay = softwareSystem "AllPay" "Direct Debit payment processor" {
            tags "External"
          }
          eckoh = softwareSystem "Eckoh" "Card payment telephone contact centre" {
            tags "External"
          }
          barclaycard = softwareSystem "Barclaycard" "Sends payment requests to" {
            tags "External"
          }
          banks = softwareSystem "Bank accounts" {
            tags "External"
          }
        }

        group "Documents" {
          xerox = softwareSystem "Xerox" "Correspondence and Cheque printing and posting" {
            tags "External"
          }
          northgate = softwareSystem "Northgate" "Document scanning, via postal service, and storage service" {
            tags "External"
          }
        }

        marstons = softwareSystem "Martsons" "Debt collections agency" {
          tags "External"
        }
        providerCms = softwareSystem "Provider CMS" "Provider system for managing cases" {
          tags "External"
        }

        benefitChecker -> dwp "Relays queries to"

        apply -> ccms "Gets provider details and reference data from and submits application through"
        applyApp -> providerDetailsAPI "Gets provider details from"
        applyApp -> soa "Gets reference data and submits legal aid application through [SOAP]"
        applyApp -> cfe "Checks applicant financial eligibility through"
        applyApp -> lfa "Checks legal aid application requirements"
        applyApp -> benefitChecker "Checks if applicant receives passported benefit through [SOAP]"
        applyApp -> portal "Authenticates users through [SAML]"
        applyApp -> hmrcInterface "Checks applicants HMRC employment information through"
        hmrcInterface -> hmrc "Requests income data from"

        applyApp -> geckoboard "Sends metrics to"
        applyApp -> trueLayer "Gets applicant bank information from"
        applyApp -> notify "Sends email using"
        applyApp -> osPlaces "Gets address data from"
        applyApp -> bankHolidaysApi "Gets bank holiday dates from"

        citizen -> applyApp "Applies for civil legal aid using"
        citizen -> applyApp "Gives bank access authorisation to"
        citizen -> eckoh "Makes payment by giving card details"
        provider -> applyApp "Fills civil legal aid application through"
        notify -> citizen "Sends email to"
        provider -> pui "Fills legal aid application and submits billing claims through"
        civilMeansCaseworker -> oracleForms "Reviews legal aid applications and makes decisions on means"
        civilMeritsCaseworker -> oracleForms "Reviews legal aid applications and makes decisions on merits"
        billingCaseworker -> oracleForms "Verifies provider bills"
        provider -> portal "Logs into"
        provider -> cccd "Submits a billing claim"
        billingCaseworker -> cccd "Starts a claim assessment"
        billingCaseworker -> cclf "Processes claims for litigators fees"
        billingCaseworker -> ccr "Processes claims for advocates fees"
        billingCaseworker -> vcd "Views court data"
        providerCms -> cccdApi "Submits billing claims"
        criminalCaseworker -> maatApp "Assesses means and interests of justice for criminal legal aid applications"
        criminalCaseworker -> mlra "Reviews magistrates court outcomes and notifies of legal aid decisions, manages representation orders"
        criminalCaseworker -> vcd "Views court data"
        provider -> eforms "Fills criminal legal aid application through"
        provider -> eforms "Submits bills for certain types of criminal legal aid through"
        criminalCaseworker -> eforms "Reviews applications for criminal legal aid in"
        billingCaseworker -> eforms "Reviews certain types of claim for criminal legal aid in"

        cwaDb -> portal "Syncs user authentication details"
        cwaDb -> ccmsDb "Syncs user data [HUB]"
        cwaDb -> eforms "Sends data about legal aid providers [HUB]"
        cwaDb -> eric "Pushes provider details [HUB]"
        cwaDb -> cisDb "Pushes claims and provider details [HUB]"
        edw -> cwaDb "Copies data from"

        pui -> portal "Authenticates provider users through [SAML]"
        oracleForms -> portal "Authenticates internal users through [SAML]"
        ebs -> benefitChecker "Checks if applicant receives passported benefit through [SOAP]"
        ebs -> allPay "Pushes Direct Debit mandate instructions, pulls mandate confirmations and changes"
        ccms -> eckoh "Pulls daily attempted card payment details (AKA MOD331)"
        eckoh -> barclaycard "Sends payment requests to"
        ebs -> barclaycard "Pulls processed card payments into Oracle Financials accounts receivables (AKA MOD332)"
        ebs -> cwaDb "Looks up provider contracts"
        ebs -> xerox "Transfers a nightly ZIP of PDF correspondence, and XML manifest, to be printed and posted [FTP]"
        ebs -> northgate "Manages documents in [SOAP]"
        ebs -> marstons "Pushes customer invoice and contribution details for debt collection (AKA MOD323)"
        ebs -> banks "Pulls payment transaction into the EBS General Ledger"
        pui -> osPlaces "Gets address data from"

        cisDb -> ccr "Takes claims from [HUB]"
        cisDb -> cclf "Takes claims from [HUB]"
        cis -> ccmsDb "Pushes CIS invoices approved for payment and, after payment, updates status of invoices in CIS [HUB]"
        edw -> cisDb "Copies data from"

        cclfDb -> maatDb "Loads defendant and court outcome data from [HUB]"
        ccrDb -> maatDb "Loads defendant and court outcome data from [HUB]"
        maatApi -> cdaApi "Sends status updates to and processes court events from"
        maatApi -> cdaSqs "Processes court update notifications from"
        cdaApi -> maatApi "Uses MAAT API to validate MAAT IDs before sending requests to Common Platform"
        cdaApi -> commonPlatform "Uses APIs to search & retreive case information, marks cases to receive notifications"
        maatApp -> benefitChecker "Check applicant benefits status [SOAP]"
        eforms -> portal "Authenticates users through [SAML]"
        eforms -> benefitChecker "Checks if applicant receives passported benefit through [SOAP]"

        mlra -> maatDb "Connects to"
        mlra -> infox "Searches cases in Libra and sends legal aid status to Libra"
        infox -> maatDb "Writes court outcome updates to"
        infox -> libra "Sends legal aid status, fetches court outcomes"
        infox -> nolasa "Sends cases that cannot be found yet on Libra for auto-rechecking"
        nolasa -> infox "Searches to see if cases can be found in Libra at set intervals"
        
        crimeApplyApp -> portal "Authenticates provider users through [SAML]"
        crimeReviewApp -> azure "Authenticates caseworker users through"
        crimeApplyApp -> benefitChecker "Checks if applicant receives passported benefit through [SOAP]"
        crimeApplyApp -> postcodeapi "Gets address data for a client [REST]"
        crimeReviewApp -> crimeDatastoreApi "Fetches applications for criminal legal aid"
           crimeDatastoreApi -> crimeDatastoreDb "Connects to"
    }

    


    views {
        systemContext apply "ApplyContext" {
            include *
            autoLayout
        }

        container apply "CivilApply" {
            include *
            autoLayout lr
        }

        systemContext ccms "ccmsContext" {
            include *
            autoLayout
        }

        container ccms "CCMS" {
            include *
            autoLayout
        }

        systemContext cccd "cccdContext" {
            include *
            autoLayout
        }

        container cccd "CCCD" {
            include *
            autoLayout
        }

        systemContext maat "maatContext" {
            include *
            autoLayout
        }

        container maat "MAAT" {
            include *
            autoLayout
        }

        systemContext crimeApply "CrimeApplyContext" {
            include *
            autoLayout
        }

      

        systemContext crimeReview "CrimeReviewContext" {
            include *
            autoLayout
        }

        systemLandscape landscape {
            include *
            autoLayout
        }

        systemLandscape landscapecrimeapps {
            include 1
            autoLayout
        }

         dynamic crimeapply "CrimeApps" "Summarises how the crime apply application talks to crime review and MAAT" {
            crimeApplyApp -> portal "Authenticates provider users through [SAML]"
        crimeReviewApp -> azure "Authenticates caseworker users through"
        crimeApplyApp -> benefitChecker "Checks if applicant receives passported benefit through [SOAP]"
        crimeApplyApp -> postcodeapi "Gets address data for a client [REST]"
        crimeApplyApp -> crimeDatastoreApi "Submits applications for criminal legal aid"
            crimeReviewApp -> crimeDatastoreApi "Fetches applications for criminal legal aid"
           crimeDatastoreApi -> crimeDatastoreDb "Connects to"
            maatApi -> crimeDatastoreApi "Fetches applications for criminal legal aid"
        autoLayout
        description "Summarises how the crime apply application talks to crime review and MAAT"


      
        }
        
        systemContext cda "cdaContext" {
           include *
           autoLayout
        }

        container cda "CDA" {
            include *
            autoLayout
        }
        container crimeApply "CrimeApplyContainer" {
            include *
            autoLayout
        }
        container crimeReview "CrimeReviewContainer" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #aabbdd
            }

            element "External" {
                background #ffffff
                color #000000
                shape RoundedBox
            }

            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }

}
