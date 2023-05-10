module EquifaxCredit
  module V2
    class IndepthCompanyTradingHistoryResponse < ActiveRecord::Base
      self.table_name = 'veda_credit_commercial_responses'

      belongs_to :indepth_company_trading_history_request, foreign_key: 'commercial_request_id', dependent: :destroy

      serialize :headers

      validates :commercial_request_id, presence: true
      validates :xml, presence: true

      def to_s
        'Equifax Credit Indepth Company Trading History Response'
      end

      def type
        get_hash('/type')
      end

      def client_reference
        get_hash('/client-reference')
      end

      def individual_consent_list
        @individual_consent_list ||= begin
          result = get_hash('/individual-consent-list')['individual_consent_list']

          output = {
            'request_id' => result['request_id'],
            'individual_consent_requests' => []
          }

          result['individual_consent_request'].ensure_array.each do |item|
            output['individual_consent_requests'] << {
              'bureau_reference' => item['bureau_reference'],
              'individual_name' => {
                'family_name' => item['family_name'],
                'first_given_name' => item['first_given_name'],
                'other_given_name' => item['other_given_name']
              },
              'date_of_birth' => value_to_date(item['date_of_birth'])
            }
          end
          output
        end
      rescue
        {}
      end

      def in_depth_trading_history_report
        @in_depth_trading_history_report ||= begin
          {
            'organisation_report_header' => organisation_report_header,
            'company_response' => company_response,
            'in_depth_director_list' => in_depth_director_list,
            'director_warning_list' => director_warning_list,
            'faults' => faults
          }
        end
      end

      def organisation_report_header
        @organisation_report_header ||= begin
          result = get_hash('/in-depth-trading-history-report/organisation-report-header')['organisation_report_header']

          {
            'request_id' => result['request_id'],
            'member_code' => result['member_code'],
            'branch_code' => result['branch_code'],
            'channel_code' => result['channel_code'],
            'charge_back_code' => result['charge_back_code'],
            'report_create_date' => value_to_datetime(result['report_create_date']),
            'pdf_link' => result['pdf_link'],
            'with_links' => result['with_links'],
            'trade_payments_required' => result['trade_payments_required'],
            'extract_date' => {
              'asic_extract_date' => value_to_date(result['asic_extract_date']),
              'asic_extract_time' => result['asic_extract_time']
            },
            'organisation_name' => result['organisation_name']
          }
        end
      rescue
        {}
      end

      def company_response
        @company_response ||= begin
          {
            'organisation_details' => organisation_details,
            'classification' => classification,
            'organisation_credit_history' => organisation_credit_history,
            'summary_data' => summary_data,
            'trade_payments' => trade_payments,
            'company_identity' => company_identity,
            'ownership_officers' => ownership_officers,
            'company_shares_list' => company_shares_list,
            'organisation_legal' => organisation_legal,
            'asic_documents' => asic_documents,
            'ppsr_registrations' => ppsr_registrations,
            'score' => score,
            'df_address' => df_address
          }
        end
      end

      def organisation_details
        @organisation_details ||= begin
          result = get_hash('/in-depth-trading-history-report/company-response/organisation-details')['organisation_details']

          output = {
            'abn_code' => result['abn_code'],
            'abn_status_code' => result['abn_status_code'],
            'abn_status_from_date' => result['abn_status_from_date'],
            'entity_type_description' => result['entity_type_description'],
            'main_legal_name' => result['main_legal_name'],
            'business_address_state_code' => result['business_address_state_code'],
            'business_address_post_code' => result['business_address_post_code'],
            'gst_status_code' => result['gst_status_code'],
            'gst_status_from_date' => value_to_date(result['gst_status_from_date']),
            'asic_number_code' => result['asic_number_code'],
            'abr_last_updated_date' => value_to_date(result['abr_last_updated_date']),
            'deductible_gift_recipients' => [],
            'other_entities' => []
          }

          result['deductible_gift_recipients'].ensure_array.each do |item|
            output['deductible_gift_recipients'] << item
          end if result['deductible_gift_recipients'].present?

          result['other_entities']['entity_name'].ensure_array.each do |item|
            output['other_entities'] << item
          end if result['other_entities'].present?

          output
        end
      rescue
        {}
      end

      def classification
        @classification ||= begin
          result = get_hash('/in-depth-trading-history-report/company-response')['company_response']
          output = []

          result['classification'].ensure_array.each do |item|
            output << {
              'division_description' => item['division_description'],
              'division_code' => item['division_code'],
              'sub_division_description' => item['sub_division_description'],
              'sub_division_code' => item['sub_division_code'],
              'group_description' => item['group_description'],
              'group_code' => item['group_code']
            }
          end if result['classification'].present?

          output
        end
      rescue
        []
      end

      def organisation_credit_history
        @organisation_credit_history ||= begin
          result = get_hash('/in-depth-trading-history-report/company-response/organisation-credit-history')['organisation_credit_history']

          output = {
            'payment_defaults' => [],
            'mercantile_enquiries' => [],
            'all_credit_enquiries' => {
              'credit_enquiries' => [],
              'broker_agent_enquiries' => []
            },
            'file_notes' => []
          }

          output['payment_defaults'] = hash_to_defaults(result['payment_default_list']['payment_defaults']) if result['payment_default_list'].present?

          result['mercantile_enquiry_list']['mercantile_enquiries'].ensure_array.each do |item|
            output['mercantile_enquiries'] << {
              'seq' => item['seq'],
              'account_type' => item['account_type'],
              'role' => item['role'],
              'co_borrower' => item['co_borrower'],
              'amount' => item['amount'].to_f,
              'client_name' => item['client_name'],
              'enquirer' => item['enquirer'],
              'report_reason' => item['report_reason'],
              'status_date' => value_to_date(item['status_date']),
              'payment_status' => item['payment_status'],
              'coll_date' => value_to_date(item['coll_date'])
            }
          end if result['mercantile_enquiry_list'].present?

          %w(credit broker_agent).each do |group|
            output['all_credit_enquiries']["#{group}_enquiries"] = hash_to_credit_enquiries(result['all_credit_enquiry_list']["#{group}_enquiry_list"]["#{group}_enquiry"]) if result['all_credit_enquiry_list']["#{group}_enquiry_list"].present?
          end

          output['file_notes'] = hash_to_file_notes(result['file_note_list']['file_note']) if result['file_note_list'].present?

          output
        end
      end

      def summary_data
        @summary_data ||= begin
          results = get_hash('/in-depth-trading-history-report/company-response/summary-data')['summary_data']

          output = hash_to_summary_data(results)

          # Legacy value for backwards compatability
          output['age_of_file'] = age_of_file if output.present?

          output
        end
      rescue
        {}
      end

      def trade_payments
        @trade_payments ||= begin
          result = get_hash('/in-depth-trading-history-report/company-response/trade-payments')['trade_payments']

          if result.present?
            output = {
              'payment_summary' => {},
              'payment_history' => {},
              'late_payment_days' => {},
              'industry_payment_experiences' => {}
            }

            if (payment_summary = result['payment_summary'])
              output['payment_summary'] = {
                'trade_references' => value_to_integer(payment_summary['trade_references']),
                'total_owing' => value_to_float(payment_summary['total_owing']),
                'total_past_due' => value_to_float(payment_summary['total_past_due']),
                'within_terms' => value_to_float(payment_summary['within_terms']),
                'owing_1_to_30' => value_to_float(payment_summary['owing_1_to_30']),
                'owing_31_to_60' => value_to_float(payment_summary['owing_31_to_60']),
                'owing_61_to_90' => value_to_float(payment_summary['owing_61_to_90']),
                'owing_91_plus' => value_to_float(payment_summary['owing_91_plus']),
                'average_owed' => value_to_float(payment_summary['average_owed']),
                'percent_debt_31_plus' => value_to_float(payment_summary['percent_debt_31_plus']),
                'percent_debt_61_plus' => value_to_float(payment_summary['percent_debt_61_plus']),
                'percent_debt_91_plus' => value_to_float(payment_summary['percent_debt_91_plus']),
                'maximum_debt_31_plus' => value_to_float(payment_summary['maximum_debt_31_plus']),
                'maximum_debt_61_plus' => value_to_float(payment_summary['maximum_debt_61_plus']),
                'maximum_debt_91_plus' => value_to_float(payment_summary['maximum_debt_91_plus']),
                'maximum_now_owing' => value_to_float(payment_summary['maximum_now_owing']),
                'maximum_now_past_due' => value_to_float(payment_summary['maximum_now_past_due']),
                'within_terms_percent' => value_to_float(payment_summary['within_terms_percent']),
                'owing_1_to_30_percent' => value_to_float(payment_summary['owing_1_to_30_percent']),
                'owing_31_to_60_percent' => value_to_float(payment_summary['owing_31_to_60_percent']),
                'owing_61_to_90_percent' => value_to_float(payment_summary['owing_61_to_90_percent']),
                'owing_91_plus_percent' => value_to_float(payment_summary['owing_91_plus_percent'])
              }
            end

            if (payment_history = result['payment_history'])
              output['payment_history'] = {
                'payment_references_by_debt_size' => [],
                'aggregated_payment_references' => [],
                'last_200_payment_references' => []
              }

              payment_history['payment_references_by_debt_size']['payment_references_summary'].ensure_array.each do |item|
                output['payment_history']['payment_references_by_debt_size'] << {
                  'row_number' => item['row_number'],
                  'description' => item['description'],
                  'payment_reference_count' => value_to_integer(item['payment_reference_count']),
                  'total_owing' => value_to_float(item['total_owing']),
                  'percent_within_terms' => value_to_float(item['percent_within_terms']),
                  'percent_1_to_30_days' => value_to_float(item['percent_1_to_30_days']),
                  'percent_31_to_60_days' => value_to_float(item['percent_31_to_60_days']),
                  'percent_61_to_90_days' => value_to_float(item['percent_61_to_90_days']),
                  'percent_91_plus_days' => value_to_float(item['percent_91_plus_days'])
                }
              end if payment_history['payment_references_by_debt_size'].present?

              payment_history['aggregated_payment_references']['aggregated_payment_reference'].ensure_array.each do |item|
                output['payment_history']['aggregated_payment_references'] << {
                  'period' => item['period'],
                  'total_owed' => value_to_float(item['total_owed']),
                  'within_terms' => value_to_float(item['within_terms']),
                  'overdue_1_to_30_days' => value_to_float(item['overdue_1_to_30_days']),
                  'overdue_31_to_60_days' => value_to_float(item['overdue_31_to_60_days']),
                  'overdue_61_to_90_days' => value_to_float(item['overdue_61_to_90_days']),
                  'overdue_91_plus_days' => value_to_float(item['overdue_91_plus_days'])
                }
              end if payment_history['aggregated_payment_references'].present?

              payment_history['last_200_payment_references']['payment_reference_detail'].ensure_array.each do |item|
                output['payment_history']['last_200_payment_references'] << {
                  'period' => item['period'],
                  'data_provider_id' => value_to_integer(item['data_provider_id']),
                  'sub_division_description' => item['sub_division_description'],
                  'total_amount' => value_to_float(item['total_amount']),
                  'current_amount' => value_to_float(item['current_amount']),
                  'amount_overdue_1_to_30_days' => value_to_float(item['amount_overdue_1_to_30_days']),
                  'amount_overdue_31_to_60_days' => value_to_float(item['amount_overdue_31_to_60_days']),
                  'amount_overdue_61_to_90_days' => value_to_float(item['amount_overdue_61_to_90_days']),
                  'amount_overdue_91_plus_days' => value_to_float(item['amount_overdue_91_plus_days'])
                }
              end if payment_history['last_200_payment_references'].present?
            end

            if (late_payment_days = result['late_payment_days'])
              output['late_payment_days'] = {
                'current_late_payment_days' => value_to_integer(result['late_payment_days']['current_late_payment_days']),
                'current_universe_late_payment_days' => value_to_integer(result['late_payment_days']['current_universe_late_payment_days']),
                'late_payment_trend' => value_to_integer(result['late_payment_days']['late_payment_trend']),
                'industry_late_payment_days' => [],
                'market_late_payment_days_history' => []
              }

              late_payment_days['industry_late_payment_days']['industry_late_payment_days_item'].ensure_array.each do |item|
                output['late_payment_days']['industry_late_payment_days'] << {
                  'sub_division_code' => item['sub_division_code'],
                  'sub_division_description' => item['sub_division_description'],
                  'average_late_payment_days' => value_to_integer(item['average_late_payment_days'])
                }
              end if late_payment_days['industry_late_payment_days'].present?

              late_payment_days['market_late_payment_days_history']['market_late_payment_days_item'].ensure_array.each do |item|
                output['late_payment_days']['market_late_payment_days_history'] << {
                  'period' => item['period'],
                  'sort_order' => value_to_integer(item['sort_order']),
                  'market_late_payment_days' => value_to_integer(item['market_late_payment_days'])
                }
              end if late_payment_days['market_late_payment_days_history'].present?
            end

            if (industry_payment_experiences = result['industry_payment_experiences'])
              output['industry_payment_experiences'] = {
                'industry_scores' => [],
                'days_beyond_term_industries' => []
              }

              industry_payment_experiences['industry_scores']['industry_score_range'].ensure_array.each do |item|
                y_points = []
                item['y_points']['y_point_mapping'].ensure_array.each do |point|
                  y_points << {
                    'industry_reference' => point['industry_reference'],
                    'y_point' => value_to_integer(point['y_point'])
                  }
                end
                output['industry_payment_experiences']['industry_scores'] << {
                  'rank' => value_to_integer(item['rank']),
                  'value' => value_to_integer(item['value']),
                  'x_point' => item['x_point'],
                  'y_points' => y_points
                }
              end if industry_payment_experiences['industry_scores'].present?

              industry_payment_experiences['days_beyond_term_industries']['industry_days_beyond_term'].ensure_array.each do |item|
                output['industry_payment_experiences']['days_beyond_term_industries'] << {
                  'industry_id' => value_to_integer(item['industry_id']),
                  'sub_division_code' => item['sub_division_code'],
                  'sub_division_description' => item['sub_division_description'],
                  'days_beyond_term' => value_to_integer(item['days_beyond_term'])
                }
              end if industry_payment_experiences['days_beyond_term_industries'].present?
            end
          end

          output
        end
      rescue
        {}
      end

      def company_identity
        @company_identity ||= begin
          result = get_hash('/in-depth-trading-history-report/company-response/company-identity')['company_identity']

          output = {
            'bureau_info' => {
              'bureau_reference' => result['bureau_info']['bureau_reference'],
              'file_creation_date' => value_to_date(result['bureau_info']['file_creation_date'])
            },
            'organisation_name' => result['organisation_name'],
            'organisation_type' => result['organisation_type'],
            'organisation_status' => result['organisation_status'],
            'organisation_name_start_date' => value_to_date(result['organisation_name_start_date']),
            'australian_business_number' => result['australian_business_number'],
            'nature_of_business' => result['nature_of_business'],
            'renewal_date' => value_to_date(result['renewal_date']),
            'last_search_date' => value_to_date(result['last_search_date']),
            'principal_place_of_business' => {
              'first_reported_date' => value_to_date(result['principal_place_of_business']['first_reported_date']),
              'address_lines' => hash_to_address_lines(result['principal_place_of_business']['address_lines']),
              'document_details' => result['principal_place_of_business']['document_details']
            },
            'australian_company_number' => result['australian_company_number'],
            'incorporation' => {
              'incorporation_date' => value_to_date(result['incorporation']['incorporation_date']),
              'incorporation_state' => result['incorporation']['incorporation_state']
            },
            'registered_office' => {
              'first_reported_date' => value_to_date(result['registered_office']['first_reported_date']),
              'address_lines' => hash_to_address_lines(result['registered_office']['address_lines']),
              'document_details' => result['registered_office']['document_details']
            },
            'asic_company_details' => {
              'previous_state_number' => result['asic_company_details']['previous_state_number'],
              'australian_company_number_review_date' => value_to_date(result['asic_company_details']['australian_company_number_review_date']),
              'organisation_class' => result['asic_company_details']['organisation_class'],
              'organisation_subclass' => result['asic_company_details']['organisation_subclass'],
              'document_details' => result['asic_company_details']['document_details']
            },
            'previous_name' => []
          }

          result['previous_name'].ensure_array.each do |item|
            output['previous_name'] << {
              'organisation_name' => item['organisation_name'],
              'organisation_type' => item['organisation_type'],
              'organisation_name_start_date' => value_to_date(item['organisation_name_start_date']),
              'cease_date' => value_to_date(item['cease_date']),
              'organisation_status' => item['organisation_status'],
              'organisation_class' => item['organisation_class'],
              'organisation_subclass' => item['organisation_subclass'],
              'document_details' => item['document_details']
            }
          end

          # Legacy value for backwards compatability
          if output['registered_office']
            address_line1 = output['registered_office']['address_lines']['street_details']
            address_line2 = [(output['registered_office']['address_lines']['locality_details']), (output['registered_office']['address_lines']['state']), (output['registered_office']['address_lines']['postcode'])].join(' ')
            output['registered_office']['address'] = [address_line1, address_line2].join(', ')
          end

          # Legacy value for backwards compatability
          if output['principal_place_of_business']
            address_line1 = output['principal_place_of_business']['address_lines']['street_details']
            address_line2 = [(output['principal_place_of_business']['address_lines']['locality_details']), (output['principal_place_of_business']['address_lines']['state']), (output['principal_place_of_business']['address_lines']['postcode'])].join(' ')
            output['principal_place_of_business']['address'] = [address_line1, address_line2].join(', ')
          end

          output
        end
      rescue
        {}
      end

      def ownership_officers
        @ownership_officers ||= begin
          result = get_hash('/in-depth-trading-history-report/company-response/ownership-officers')['ownership_officers']

          output = {
            'share_holders' => [],
            'previous_share_holders' => [],
            'directors' => [],
            'secretaries' => [],
            'previous_secretaries' => [],
            'other_officers' => [],
            'other_previous_officers' => [],
            'other_organisation_officers' => [],
            'other_previous_organisation_officers' => [],
            'proprietorships' => []
          }

          %w(share_holder previous_share_holder).each do |group|
            result["#{group}_list"]['share_holder'].ensure_array.each do |item|
              output["#{group}s"] << {
                'individual_share_holder' => item['individual_share_holder'],
                'organisation_share_holder' => item['organisation_share_holder'],
                'document_details' => item['document_details'],
                'history_flag' => item['history_flag'],
                'share_class_code' => item['share_class_code'],
                'shares_held' => item['shares_held'],
                'beneficial_ownership' => item['beneficial_ownership'],
                'fully_paid_flag' => item['fully_paid_flag'],
                'joint_holding' => item['joint_holding']
              }
            end if result["#{group}_list"].present?
          end

          %w(directors previous_directors).each do |group|
            result["#{group}_list"]['directors'].ensure_array.each do |item|
              output[group] << {
                'seq' => item['seq'],
                'bureau_reference' => item['bureau_reference'],
                'appointment_date' => value_to_date(item['appointment_date']),
                'individual_name' => item['individual_name'],
                'gender' => item['gender'],
                'date_of_birth' => value_to_date(item['date_of_birth']),
                'birth_details' => item['birth_details'],
                'residency_overseas' => item['residency_overseas'],
                'address' => item['address'],
                'document_details' => item['document_details'],
                'court_details' => item['court_details'],
                'file_messages' => hash_to_file_messages(item['file_message_list']),
                'cease_date' => value_to_date(item['cease_date']),
                'last_known_date' => value_to_date(item['last_known_date'])
              }
            end if result["#{group}_list"].present?
          end

          %w(secretary previous_secretary other_officers other_previous_officers other_organisation_officers other_previous_organisation_officers).each do |group|
            result["#{group}_list"][group.pluralize].ensure_array.each do |item|
              output[group.pluralize] << {
                'document_details' => item['document_details'],
                'office' => item['office'],
                'history_flag' => item['history_flag'],
                'appointment_date' => value_to_date(item['appointment_date']),
                'cease_date' => value_to_date(item['cease_date']),
                'individual_officer' => item['individual_officer'],
                'organisation_officer' => item['organisation_officer'],
                'address_lines' => hash_to_address_lines(item['address_lines']),
                'court_details' => item['court_details']
              }
            end if result["#{group}_list"].present?
          end

          output['proprietorships'] = hash_to_proprietorships(result['proprietorship_list']['proprietorship']) if result['proprietorship_list'].present?

          output
        end
      rescue
        {}
      end

      def company_shares
        @company_shares ||= begin
          result = get_hash('/in-depth-trading-history-report/company-response/company-shares-list')['company_shares_list']

          output = {
            'annual_general_meeting_date' => value_to_date(result['current_company_shares']['annual_general_meeting_date']),
            'lodge_date' => value_to_date(result['current_company_shares']['lodge_date']),
            'current_company_shares' => [],
            'previous_company_shares' => []
          }

          %w(current previous).each do |group|
            result["#{group}_company_shares"]['company_share'].ensure_array.each do |item|
              output["#{group}_company_shares"] << {
                'document_details' => item['document_details'],
                'history_flag' => item['history_flag'],
                'share_class_code' => item['share_class_code'],
                'share_class_title' => item['share_class_title'],
                'shares_issued' => item['shares_issued'].to_i,
                'paid_capital' => item['paid_capital'].to_f,
                'unpaid_capital' => item['unpaid_capital'].to_f
              }
            end if result["#{group}_company_shares"].present?
          end

          output
        end
      rescue
        {}
      end

      def organisation_legal
        @organisation_legal ||= begin
          result = get_hash('/in-depth-trading-history-report/company-response/organisation-legal')['organisation_legal']

          output = {
            'writs' => [],
            'judgements' => [],
            'file_messages' => [],
            'external_administrators' => [],
            'petitions' => []
          }

          output['writs'] = hash_to_writs(result['court_writ_list']['writs']) if result['court_writ_list'].present?

          output['judgements'] = hash_to_judgements(result['court_judgement_list']['judgements']) if result['court_judgement_list'].present?

          output['file_messages'] = hash_to_file_messages(result['file_message_list']) if result['file_message_list'].present?

          result['external_administrator_list']['external_administrators'].ensure_array.each do |item|
            output['external_administrators'] << {
              'seq' => item['seq'],
              'administrator_title' => item['administrator_title'],
              'administrator_name' => item['administrator_name'],
              'administrator_address' => item['administrator_address'],
              'administrator_document_number' => item['administrator_document_number'],
              'administrator_start_date' => value_to_date(item['administrator_start_date']),
              'administrator_end_date' => value_to_date(item['administrator_end_date']),
              'creditor' => item['creditor'],
              'court_number' => item['court_number']
            }
          end if result['external_administrator_list'].present?

          result['petition_list']['petition'].ensure_array.each do |item|
            output['petitions'] << {
              'seq' => item['seq'],
              'creditor' => item['creditor'],
              'court_number' => item['court_number'],
              'liquidator' => item['liquidator'],
              'petition_date' => value_to_date(item['petition_date']),
              'hearing_date' => value_to_date(item['hearing_date'])
            }
          end if result['petition_list'].present?

          output
        end
      rescue
        {}
      end

      def asic_documents
        @asic_documents ||= begin
          result = get_hash('/in-depth-trading-history-report/company-response/asic-documents')['asic_documents']

          output = {
            'documents' => [],
            'pre_asic_documents' => [],
            'annual_returns' => [],
            'financial_reports' => [],
            'company_addresses' => {
              'current_company_addresses' => [],
              'previous_company_addresses' => [],
              'future_company_addresses' => []
            }
          }

          result['document_list']['document_item'].ensure_array.each do |item|
            output['documents'] << {
              'document_details' => item['document_details'],
              'received_date' => value_to_date(item['received_date']),
              'form_code' => item['form_code'],
              'sub_form_code' => item['sub_form_code'],
              'description' => item['description'],
              'processed_date' => value_to_date(item['processed_date']),
              'pages' => value_to_integer(item['pages']),
              'effective_date' => value_to_date(item['effective_date']),
              'requisition_flag' => item['requisition_flag'],
              'xbrl_flag' => item['xbrl_flag']
            }
          end if result['document_list'].present?

          result['document_list']['pre_asic_documents'].ensure_array.each do |item|
            output['pre_asic_documents'] << {
              'state' => item['state'],
              'received_date' => value_to_date(item['received_date']),
              'form_code' => item['form_code'],
              'document_status' => item['document_status']
            }
          end if result['document_list'].present?

          result['annual_returns_list']['annual_returns'].ensure_array.each do |item|
            output['annual_returns'] << {
              'returns_year' => item['returns_year'],
              'outstanding' => item['outstanding'],
              'return_due_date' => value_to_date(item['return_due_date']),
              'extended_return_due_date' => value_to_date(item['extended_return_due_date']),
              'annual_general_meeting_due_date' => value_to_date(item['annual_general_meeting_due_date']),
              'extended_annual_general_meeting_due_date' => value_to_date(item['extended_annual_general_meeting_due_date']),
              'annual_general_meeting_held_date' => value_to_date(item['annual_general_meeting_held_date'])
            }
          end if result['annual_returns_list'].present?

          result['financial_reports_list']['financial_reports'].ensure_array.each do |item|
            output['financial_reports'] << {
              'balance_date' => value_to_date(item['balance_date']),
              'report_due_date' => value_to_date(item['report_due_date']),
              'annual_general_meeting_due_date' => value_to_date(item['annual_general_meeting_due_date']),
              'extended_annual_general_meeting_due_date' => value_to_date(item['extended_annual_general_meeting_due_date']),
              'annual_general_meeting_held_date' => value_to_date(item['annual_general_meeting_held_date']),
              'outstanding' => item['outstanding'],
              'document_number' => item['document_number']
            }
          end if result['financial_reports_list'].present?

          %w(current previous future).each do |group|
            result['company_address_list']["#{group}_company_addresses"].ensure_array.each do |item|
              output['company_addresses']["#{group}_company_addresses"] << {
                'document_details' => item['document_details'],
                'history_flag' => item['history_flag'],
                'address_plus' => hash_to_address_plus(item['address_plus'])
              }
            end if result['company_address_list'].present?
          end

          output
        end
      rescue
        {}
      end

      def ppsr_registrations
        @ppsr_registrations ||= begin
          result = get_hash('/in-depth-trading-history-report/company-response/ppsr-registrations')['ppsr_registrations']

          if result.present?
            output = {
              'report_information' => {
                'search_number' => result['search_number'],
                'search_date' => value_to_datetime(result['search_date']),
                'search_type' => result['search_type'],
                'grantor_search_criteria' => {
                  'organisation_name' => result['grantor_search_criteria']['organisation_name'],
                  'organisation_number' => result['grantor_search_criteria']['organisation_number'],
                  'organisation_number_type' => result['grantor_search_criteria']['organisation_number_type'],
                  'ppsr_notes' => result['grantor_search_criteria']['ppsr_notes']
                }
              },
              'registration_summary' => {
                'total_registrations' => value_to_integer(result['registration_summary']['total_registrations']),
                'total_registrations_under_twelve_months' => value_to_integer(result['registration_summary']['total_registrations_under_twelve_months']),
                'total_registrations_over_twelve_months' => value_to_integer(result['registration_summary']['total_registrations_over_twelve_months']),
                'total_pmsi_registrations' => value_to_integer(result['registration_summary']['total_pmsi_registrations']),
                'total_registrations_designated_secured_parties' => value_to_integer(result['registration_summary']['total_registrations_designated_secured_parties']),
                'total_registrations_other_financier_secured_parties' => value_to_integer(result['registration_summary']['total_registrations_other_financier_secured_parties'])
              },
              'commercial_collateral_class_summaries' => [],
              'registrations' => []
            }

            result['commercial_collateral_class_summary']['collateral_class_summary'].ensure_array.each do |item|
              output['commercial_collateral_class_summaries'] << {
                'registration_type' => item['registration_type'],
                'total_registrations' => value_to_integer(item['total_registrations'])
              }
            end if result['commercial_collateral_class_summary'].present?

            result['registration_list']['registration_detail'].ensure_array.each do |item|
              output['registrations'] << {
                'registration_number' => item['registration_number'],
                'registration_start_date' => value_to_datetime(item['registration_start_date']),
                'registration_end_date' => value_to_datetime(item['registration_end_date']),
                'migrated_flag' => item['migrated_flag'],
                'collateral_class' => item['collateral_class'],
                'pmsi_flag' => item['pmsi_flag'],
                'secured_parties' => item['secured_parties'],
                'registration_elements' => item['registration_elements']
              }
            end if result['registration_list'].present?

            output
          end
        end
      rescue
        {}
      end

      def score
        @score ||= begin
          result = get_hash('/in-depth-trading-history-report/company-response/score')['score']

          hash_to_score(result)
        end
      rescue
        {}
      end

      def df_address
        @df_address ||= begin
          get_hash('/in-depth-trading-history-report/company-response/df-address')['df_address']
        end
      rescue
        {}
      end

      def in_depth_director_list
        @in_depth_director_list ||= begin
          {
            'in_depth_commercial_individual' => in_depth_commercial_individual
          }
        end
      end

      def in_depth_commercial_individual
        @in_depth_commercial_individual ||= begin
          results = get_hash('/in-depth-trading-history-report/in-depth-director-list')['in_depth_director_list']['in_depth_commercial_individual']
          individuals = []

          results.ensure_array.each do |result|
            individual = {
              'individual_identity' => nil,
              'individual_credit_history' => {
                'payment_defaults' => [],
                'credit_providers' => [],
                'all_credit_enquiries' => {
                  'credit_enquiries' => [],
                  'broker_agent_enquiries' => []
                },
                'file_notes' => []
              },
              'individual_consumer_history' => {
                'payment_defaults' => [],
                'credit_providers' => [],
                'all_credit_enquiries' => {
                  'credit_enquiries' => [],
                  'broker_agent_enquiries' => []
                },
                'file_notes' => []
              },
              'individual_legal' => {
                'writs' => [],
                'judgements' => [],
                'file_messages' => [],
                'bankruptcies' => [],
                'disqualifications' => []
              },
              'offices' => {
                'directorships' => [],
                'previous_directorships' => [],
                'proprietorship' => []
              },
              'score' => nil,
              'summary_data' => [],
              'business_relationships' => {
                'current_companies' => [],
                'previous_companies' => [],
                'current_businesses' => []
              }
            }

            if (individual_identity = result['individual_identity'])
              individual['individual_identity'] = {
                'bureau_info' => {
                  'bureau_reference' => individual_identity['bureau_info']['bureau_reference'],
                  'file_creation_date' => value_to_date(individual_identity['bureau_info']['file_creation_date'])
                },
                'individual_name' => {
                  'family_name' => individual_identity['individual_name']['family_name'],
                  'first_given_name' => individual_identity['individual_name']['first_given_name'],
                  'other_given_name' => individual_identity['individual_name']['other_given_name']
                },
                'privacy_consent' => individual_identity['privacy_consent'],
                'individual_details' => {
                  'gender' => individual_identity['individual_details']['gender'],
                  'date_of_birth' => value_to_date(individual_identity['individual_details']['date_of_birth']),
                  'drivers_licence' => individual_identity['individual_details']['drivers_licence']
                },
                'employment' => [],
                'addresses' => [],
                'cross_references' => []
              }

              individual_identity['employment_list']['employment'].ensure_array.each do |item|
                individual['individual_identity']['employment'] << {
                  'seq' => item['seq'],
                  'first_reported_date' => value_to_date(item['first_reported_date']),
                  'occupation' => item['occupation'],
                  'employer' => item['employer']
                }
              end if individual_identity['employment_list'].present?

              individual['individual_identity']['addresses'] = hash_to_addresses(individual_identity['address_list']['address']) if individual_identity['address_list'].present?

              individual_identity['cross_reference_list']['individual_cross_reference'].ensure_array.each do |item|
                individual['individual_identity']['cross_references'] << {
                  'bureau_reference' => item['bureau_reference'],
                  'creation_date' => value_to_date(item['creation_date']),
                  'individual_name' => {
                    'family_name' => item['individual_name']['family_name'],
                    'first_given_name' => item['individual_name']['first_given_name'],
                    'other_given_name' => item['individual_name']['other_given_name']
                  }
                }
              end if individual_identity['cross_reference_list'].present?
            end

            if (individual_credit_history = result['individual_credit_history'])
              individual['individual_credit_history']['payment_defaults'] = hash_to_defaults(individual_credit_history['payment_default_list']['payment_defaults']) if individual_credit_history['payment_default_list'].present?

              individual_credit_history['credit_provider_list']['credit_providers'].ensure_array.each do |item|
                individual['individual_credit_history']['credit_providers'] << hash_to_credit_provider(item)
              end if individual_credit_history['credit_provider_list'].present?

              %w(credit broker_agent).each do |group|
                individual['individual_credit_history']['all_credit_enquiries']["#{group}_enquiries"] = hash_to_credit_enquiries(individual_credit_history['all_credit_enquiry_list']["#{group}_enquiry_list"]["#{group}_enquiry"]) if individual_credit_history['all_credit_enquiry_list']["#{group}_enquiry_list"].present?
              end

              individual['individual_credit_history']['file_notes'] = hash_to_file_notes(individual_credit_history['file_note_list']['file_note']) if individual_credit_history['file_note_list'].present?
            end

            if (individual_consumer_history = result['individual_consumer_history'])
              individual['individual_consumer_history']['payment_defaults'] = hash_to_defaults(individual_consumer_history['payment_default_list']['payment_defaults']) if individual_consumer_history['payment_default_list'].present?

              individual_consumer_history['credit_provider_list']['credit_providers'].ensure_array.each do |item|
                individual['individual_consumer_history']['credit_providers'] << hash_to_credit_provider(item)
              end if individual_consumer_history['credit_provider_list'].present?

              %w(credit broker_agent).each do |group|
                individual['individual_consumer_history']['all_credit_enquiries']["#{group}_enquiries"] = hash_to_credit_enquiries(individual_consumer_history['all_credit_enquiry_list']["#{group}_enquiry_list"]["#{group}_enquiry"]) if individual_consumer_history['all_credit_enquiry_list']["#{group}_enquiry_list"].present?
              end

              individual['individual_consumer_history']['file_notes'] = hash_to_file_notes(individual_consumer_history['file_note_list']['file_note']) if individual_consumer_history['file_note_list'].present?
            end

            if (individual_legal = result['individual_legal'])
              individual['individual_legal']['writs'] = hash_to_writs(individual_legal['court_writ_list']['writs']) if individual_legal['court_writ_list'].present?

              individual['individual_legal']['judgements'] = hash_to_judgements(individual_legal['court_judgement_list']['judgements']) if individual_legal['court_judgement_list'].present?

              individual['individual_legal']['file_messages'] = hash_to_file_messages(individual_legal['file_message_list']) if individual_legal['file_message_list'].present?

              individual['individual_legal']['bankruptcies'] = hash_to_bankruptcies(individual_legal['bankruptcy_list']['bankruptcy']) if individual_legal['bankruptcy_list'].present?

              individual['individual_legal']['disqualifications'] = hash_to_disqualifications(individual_legal['disqualifications_list']['disqualifications']) if individual_legal['disqualifications_list'].present?
            end

            if (offices = result['offices'])
              individual['offices']['directorships'] = hash_to_directorships(offices['directorship_list']['directorships']) if offices['directorship_list'].present?

              individual['offices']['previous_directorships'] = hash_to_directorships(offices['directorship_list']['previous_directorships']) if offices['directorship_list'].present?

              individual['offices']['proprietorships'] = hash_to_proprietorships(offices['proprietorship_list']['proprietorship']) if offices['proprietorship_list'].present?
            end

            individual['score'] = hash_to_score(result['score']) if result['score'].present?

            individual['summary_data'] = hash_to_summary_data(result['summary_data']) if result['summary_data'].present?

            individual['business_relationships']['current_companies'] = hash_to_companies(result['business_relationships']['current_company_list']['current_company']) if result['business_relationships']['current_company_list'].present?

            individual['business_relationships']['previous_companies'] = hash_to_companies(result['business_relationships']['previous_company_list']['previous_company']) if result['business_relationships']['previous_company_list'].present?

            individual['business_relationships']['current_businesses'] = hash_to_companies(result['business_relationships']['current_business_list']['current_business']) if result['business_relationships']['current_business_list'].present?

            individuals << individual
          end

          individuals
        end
      rescue
        []
      end

      def director_warnings
        @director_warnings ||= begin
          results = get_hash('/in-depth-trading-history-report/director-warning-list')['director_warning_list']
          output = []

          results['director_warning'].ensure_array.each do |item|
            warning_meta_data = []
            item['warning_meta_data']['warning_meta_data_entry'].ensure_array.each do |entry|
              warning_meta_data << {
                'name' => entry['name'],
                'value' => entry['value'],
                'type' => entry['type']
              }
            end if item['warning_meta_data'].present?
            output << {
              'individual_name' => {
                'family_name' => item['individual_name']['family_name'],
                'first_given_name' => item['individual_name']['first_given_name'],
                'other_given_name' => item['individual_name']['other_given_name']
              },
              'individual_details' => {
                'gender' => item['individual_details']['gender'],
                'date_of_birth' => value_to_date(item['individual_details']['date_of_birth']),
                'drivers_licence' => item['individual_details']['drivers_licence']
              },
              'address' => hash_to_address(item['address']),
              'warning_message' => item['warning_message'],
              'warning_message_description' => item['warning_message_description'],
              'warning_meta_data' => warning_meta_data
            }
          end if results.present?

          output
        end
      rescue
        []
      end

      def faults
        @faults ||= begin
          get_hash('/in-depth-trading-history-report/faults')['faults']['fault']
        end
      end

      # Legacy methods for backwards compatability

      def credit_enquiries
        @credit_enquiries ||= begin
          output = (organisation_credit_history['all_credit_enquiries']['credit_enquiries'] rescue []) + (in_depth_commercial_individual['individual_credit_history']['all_credit_enquiries']['credit_enquiries'] rescue []) + (in_depth_commercial_individual['individual_consumer_history']['all_credit_enquiries']['credit_enquiries'] rescue [])
          output = [output].flatten.compact

          output.each do |item|
            item['credit_enquirer'] = item.delete('enquirer')
            item['reference_number'] = item.delete('ref_number')
            item['account_type_code'] = item['account_type']['code']
            item['account_type'] = item['account_type']['type']
            item['role_in_enquiry'] = item['role']['type']
            item.delete('role')
          end

          output
        end
      end

      def company_enquiry_header
        @company_enquiry_header ||= begin
          output = organisation_report_header

          return {} unless output.present?

          output['asic_extract_date'] = output['extract_date']['asic_extract_date']
          output.delete('extract_date')
          output['report_created'] = output.delete('report_create_date')

          output
        end
      end

      # This is for veda
      def age_of_file
        @age_of_file ||= begin
          create_date = get_hash('/in-depth-trading-history-report/company-response/company-identity//file-creation-date')['file_creation_date']
          return nil unless create_date.present?
          now = DateTime.current
          create_date = create_date.to_date
          (now.year * 12 + now.month) - (create_date.year * 12 + create_date.month)
        end
      end

      # This is our own
      def age_of_response
        (self.created_at.to_date - Date.current).to_i.abs
      end

      def file_messages
        @file_messages ||= begin
          results = organisation_legal['file_messages']

          output = []
          results.each do |item|
            output << item['narrative']
          end

          output
        end
      rescue
        []
      end

      def writs
        organisation_legal['writs']
      end

      def judgements
        organisation_legal['judgements']
      end

      def petitions
        organisation_legal['petitions']
      end

      def number_of_petitions
        petitions.count
      rescue
        0
      end

      def defaults
        @defaults ||= begin
          output = (organisation_credit_history['payment_defaults'] rescue []) + (in_depth_commercial_individual['individual_credit_history']['payment_defaults'] rescue []) + (in_depth_commercial_individual['individual_consumer_history']['payment_defaults'] rescue [])

          [output].flatten.compact
        end
      end

      def directors
        @directors ||= begin
          output = ownership_officers['directors']

          output.each do |director|
            first_names = [director['individual_name']['first_given_name'], director['individual_name']['other_given_name']].join(' ')
            surname = director['individual_name']['family_name']
            director['director_name'] = [surname, first_names].join(', ')
            director['place_of_birth'] = [director['birth_details']['birth_locality'], director['birth_details']['birth_state']].join(' ')
            if director['address'].present?
              address_line1 = [director['address']['street_number'], director['address']['street_name'], director['address']['street_type']].join(' ')
              address_line2 = [director['address']['suburb'], director['address']['state'], director['address']['postcode']].join(' ')
              director['address'] = [address_line1, address_line2].join(', ')
            else
              director['address'] = nil
            end
          end

          output
        end
      rescue
        []
      end

      def secretaries
        @secretaries ||= begin
          output = ownership_officers['secretaries']

          output.each do |secretary|
            first_names = [secretary['individual_officer']['individual_name']['first_given_name'], secretary['individual_officer']['individual_name']['other_given_name']].join(' ')
            surname = secretary['individual_officer']['individual_name']['family_name']
            secretary['secretary_name'] = [surname, first_names].join(', ')
            secretary['place_of_birth'] = [secretary['birth_details']['birth_locality'], secretary['birth_details']['birth_state']].join(' ')
            if secretary['address'].present?
              address_line1 = secretary['address_lines']['street_details']
              address_line2 = [secretary['address_lines']['locality_details'], secretary['address_lines']['state'], secretary['address_lines']['postcode']].join(' ')
              secretary['address'] = [address_line1, address_line2].join(', ')
            else
              secretary['address'] = nil
            end
          end

          output
        end
      rescue
        []
      end

      # End of legacy methods for backwards compatability

      def error
        if xml && xml.include?('<html>')
          body = %r{<body>([\s\S]*)</body>}.match(xml)[0]
          body.gsub!(/<body>|<h1>|<h3>/, ' ').gsub!(%r{</body>|</h1>|</h3>}, '').delete!("\n").strip!
          body
        elsif get_hash('/error').present?
          hsh = get_hash('/error')
          "Error: #{hsh['error']['code']} - #{hsh['error']['description']}"
        elsif get_fault_hash.present?
          hsh = get_fault_hash['Fault']['detail']['error']
          "Error: #{hsh['code']} - #{hsh['description']}"
        end
      end

      def success?
        error.nil? ? true : false
      end

      def commercial_service_version
        'New'
      end

      def service_version
        'indepth-company-trading-history'
      end

      private

      def response
        Nokogiri::XML(xml).remove_namespaces!
      end

      def get_hash(search_node = nil)
        node = response.xpath("/Envelope/Body/response#{search_node}")
        return {} unless node.present?
        Marshal.load(Marshal.dump(Hash.from_xml(node.to_s)))
      end

      def get_fault_hash(search_node = nil)
        node = response.xpath("/Envelope/Body/Fault#{search_node}")
        return {} unless node.present?
        Marshal.load(Marshal.dump(Hash.from_xml(node.to_s)))
      end

      def value_to_date(value)
        value.present? ? value.to_date : nil
      end

      def value_to_datetime(value)
        value.present? ? value.to_datetime : nil
      end

      def value_to_float(value)
        value.present? ? value.to_f : 0.0
      end

      def value_to_integer(value)
        value.present? ? value.to_i : 0
      end

      def hash_to_address(hash)
        {
          'date_current_from' => value_to_date(hash['date_current_from']),
          'type' => hash['type'],
          'property' => hash['property'],
          'unit_number' => hash['unit_number'],
          'street_number' => hash['street_number'],
          'street_name' => hash['street_name'],
          'street_type' => hash['street_type'],
          'suburb' => hash['suburb'],
          'state' => hash['state'],
          'postcode' => hash['postcode'],
          'dpid' => hash['DPID'],
          'country' => hash['country'],
          'unformatted_address' => hash['unformatted_address']
        }
      end

      def hash_to_addresses(hash)
        output = []

        hash.ensure_array.each do |item|
          output << hash_to_address(item)
        end

        output
      end

      def hash_to_address_lines(hash)
        {
          'careof' => hash['careof'],
          'address_prefix' => hash['address_prefix'],
          'street_details' => hash['street_details'],
          'locality_details' => hash['locality_details'],
          'state' => hash['state'],
          'postcode' => hash['postcode'],
          'country' => hash['country']
        }
      end

      def hash_to_address_plus(hash)
        output = hash_to_address_lines(hash)

        output['address_flag'] = hash['address_flag']
        output['address_start_date'] = value_to_date(hash['address_start_date'])
        output['address_end_date'] = value_to_date(hash['address_end_date'])

        output
      end

      def hash_to_bankruptcies(hash)
        output = []

        hash.ensure_array.each do |item|
          output << {
            'bankruptcy_date' => value_to_date(item['bankruptcy_date']),
            'bankruptcy_status' => item['bankruptcy_status'],
            'bankruptcy_narrative' => item['bankruptcy_narrative'],
            'proceedings_number' => item['proceedings_number'],
            'proceedings_year' => item['proceedings_year'],
            'proceedings_state' => item['proceedings_state'],
            'proceedings_status' => item['proceedings_status'],
            'discharge_flag' => item['discharge_flag'],
            'discharge_date' => value_to_date(item['discharge_date']),
            'role' => item['role'],
            'co_borrower' => item['co_borrower']
          }
        end

        output
      end

      def hash_to_companies(hash)
        output = []

        hash.ensure_array.each do |item|
          output << {
            'bureau_info' => {
              'bureau_reference' => item['bureau_info']['bureau_reference'],
              'file_creation_date' => value_to_date(item['bureau_info']['file_creation_date'])
            },
            'organisation_name' => item['organisation_name'],
            'australian_business_number' => item['australian_business_number'],
            'appointment_date' => value_to_date(item['appointment_date']),
            'file_messages' => hash_to_file_messages(item['file_message_list']),
            'organisation_summary' => {
              'organisation_public_count' => {
                'court_writ_count' => value_to_integer(item['organisation_summary']['organisation_public_count']['court_writ_count']),
                'court_judgement_count' => value_to_integer(item['organisation_summary']['organisation_public_count']['court_judgement_count']),
                'external_administration_count' => value_to_integer(item['organisation_summary']['organisation_public_count']['external_administration_count']),
                'petition_count' => value_to_integer(item['organisation_summary']['organisation_public_count']['petition_count']),
                'current_director_count' => value_to_integer(item['organisation_summary']['organisation_public_count']['current_director_count']),
                'previous_director_count' => value_to_integer(item['organisation_summary']['organisation_public_count']['previous_director_count']),
                'proprietorship_count' => value_to_integer(item['organisation_summary']['organisation_public_count']['proprietorship_count']),
                'organisation_proprietor_count' => value_to_integer(item['organisation_summary']['organisation_public_count']['organisation_proprietor_count']),
                'individual_proprietor_count' => value_to_integer(item['organisation_summary']['organisation_public_count']['individual_proprietor_count'])
              },
              'organisation_credit_count' => {
                'payment_default_count' => value_to_integer(item['organisation_summary']['organisation_credit_count']['payment_default_count']),
                'credit_enquiry_count' => value_to_integer(item['organisation_summary']['organisation_credit_count']['credit_enquiry_count']),
                'broker_dealer_enquiry_count' => value_to_integer(item['organisation_summary']['organisation_credit_count']['broker_dealer_enquiry_count']),
                'mercantile_enquiry_count' => value_to_integer(item['organisation_summary']['organisation_credit_count']['mercantile_enquiry_count'])
              }
            },
            'organisation_status' => item['organisation_status'],
            'organisation_type' => item['organisation_type'],
            'australian_company_number' => item['australian_company_number'],
            'last_search_date' => value_to_date(item['last_search_date']),
            'cease_date' => value_to_date(item['cease_date']),
            'last_known_date' => value_to_date(item['last_known_date']),
            'business_registration_number' => item['business_registration_number']
          }
        end

        output
      end

      def hash_to_credit_enquiries(hash)
        output = []

        hash.ensure_array.each do |item|
          output << {
            'seq' => item['seq'],
            'account_type' => item['account_type'],
            'role' => item['role'],
            'co_borrower' => item['co_borrower'],
            'amount' => item['amount'].to_i,
            'enquiry_date' => value_to_date(item['enquiry_date']),
            'enquirer' => item['enquirer'],
            'ref_number' => item['ref_number']
          }
        end

        output
      end

      def hash_to_credit_provider(hash)
        {
          'seq' => hash['seq'],
          'credit_provider' => hash['credit_provider'],
          'credit_provided_date' => value_to_date(hash['credit_provided_date']),
          'account_number' => hash['account_number']
        }
      end

      def hash_to_defaults(hash)
        output = []

        hash.ensure_array.each do |item|
          output << {
            'seq' => item['seq'],
            'account_type' => item['account_type'],
            'role' => item['role'],
            'co_borrower' => item['co_borrower'],
            'amount' => item['amount'].to_f,
            'account_number' => item['account_number'],
            'provider' => item['provider'],
            'default_date' => value_to_date(item['default_date']),
            'report_reason' => item['report_reason'],
            'original_provider' => item['original_provider'],
            'original_default_date' => item['original_default_date'],
            'original_amount' => item['original_amount'],
            'original_report_reason' => item['original_report_reason'],
            'payment_status' => item['payment_status'],
            'status_date' => value_to_date(item['status_date']),
            'serious_credit_infringement' => item['serious_credit_infringement'],
            'serious_credit_infringement_start_date' => value_to_date(item['serious_credit_infringement_start_date'])
          }
        end

        output
      end

      def hash_to_directorships(hash)
        output = []

        hash.ensure_array.each do |item|
          output << {
            'bureau_reference' => item['bureau_reference'],
            'seq' => item['seq'],
            'organisation_name' => item['organisation_name'],
            'organisation_type' => item['organisation_type'],
            'organisation_status' => item['organisation_status'],
            'australian_company_number' => item['australian_company_number'],
            'australian_business_number' => item['australian_business_number'],
            'appointment_date' => value_to_date(item['appointment_date']),
            'file_messages' => hash_to_file_messages(item['file_message_list'])
          }
        end

        output
      end

      def hash_to_disqualifications(hash)
        output = []

        hash.ensure_array.each do |item|
          output << {
            'disqualified_date' => value_to_date(item['disqualified_date']),
            'disqualified_to_date' => value_to_date(item['disqualified_to_date']),
            'file_messages' => hash_to_file_messages(item['file_message_list'])
          }
        end

        output
      end

      def hash_to_file_messages(hash)
        output = []

        hash['file_message'].ensure_array.each do |item|
          output << {
            'seq' => item['seq'],
            'narrative' => item['narrative']
          }
        end if hash.present?

        output
      end

      def hash_to_file_notes(hash)
        output = []

        hash.ensure_array.each do |item|
          output << {
            'seq' => item['seq'],
            'recorded_date' => value_to_date(item['note_recorded_date']),
            'narrative' => item['narrative']
          }
        end

        output
      end

      def hash_to_judgement(hash)
        {
          'seq' => hash['seq'],
          'action_date' => value_to_date(hash['action_date']),
          'creditor' => hash['creditor'],
          'plaint_number' => hash['plaint_number'],
          'role' => hash['role'],
          'action_status' => hash['action_status'],
          'amount' => value_to_float(hash['amount']),
          'court_type' => hash['court_type'],
          'co_borrower' => hash['co_borrower'],
          'status_date' => value_to_date(hash['status_date'])
        }
      end

      def hash_to_judgements(hash)
        output = []

        hash.ensure_array.each do |item|
          output << hash_to_judgement(item)
        end

        output
      end

      def hash_to_proprietorships(hash)
        output = []

        hash.ensure_array.each do |item|
          output << {
            'bureau_reference' => item['bureau_reference'],
            'seq' => item['seq'],
            'organisation_name' => item['organisation_name'],
            'organisation_type' => item['organisation_type'],
            'appointment_date' => value_to_date(item['appointment_date']),
            'business_registration_number' => item['business_registration_number'],
            'australian_business_number' => item['australian_business_number'],
            'file_messages' => hash_to_file_messages(item['file_message_list'])
          }
        end

        output
      end

      def hash_to_score(hash)
        output = {
          'bureau_score' => value_to_integer(hash['bureau_score']),
          'contributing_factors' => [],
          'scoring_errors' => [],
          'scoring_warnings' => [],
          'probability_adverse' => value_to_float(hash['probability_adverse']),
          'probability_failure' => value_to_float(hash['probability_failure'])
        }

        hash['contributing_factor_list']['contributing_factor'].ensure_array.each do |cf|
          output['contributing_factors'] << { 'score_factor' => cf['score_factor'], 'score_impactor' => cf['score_impactor'], 'description' => cf['contributing_factor_description'] }
        end if hash['contributing_factor_list'].present?

        hash['scoring_error_list']['scoring_error'].ensure_array.each do |se|
          output['scoring_errors'] << { 'code' => se['scoring_error_code'], 'description' => se['scoring_error_description'] }
        end if hash['scoring_error_list'].present?

        hash['scoring_warning_list']['scoring_warning'].ensure_array.each do |sw|
          output['scoring_warnings'] << { 'code' => sw['scoring_warning_code'], 'description' => sw['scoring_warning_description'] }
        end if hash['scoring_warning_list'].present?

        output
      end

      def hash_to_summary_data(hash)
        output = {}

        hash['summary_entry'].each do |se|
          output[se['summary_name'].underscore.downcase] = se['summary_value'].to_i
        end

        output
      end

      def hash_to_writs(hash)
        output = []

        hash.ensure_array.each do |item|
          writ = hash_to_judgement(item)
          writ['writ_type'] = item['writ_type']
          output << writ
        end

        output
      end
    end
  end
end

class Object
  def ensure_array
    [self]
  end
end

class Array
  def ensure_array
    to_a
  end
end

class NilClass
  def ensure_array
    to_a
  end
end
