*"* use this source file for your ABAP unit test classes

CLASS ltc_truncate_date_intervals DEFINITION DEFERRED.
CLASS zcl_range_to_intervals__dattim DEFINITION LOCAL FRIENDS ltc_truncate_date_intervals.


CLASS ltc_get_intervals DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS empty_ranges_ie_all_dates_time FOR TESTING RAISING cx_static_check.
    METHODS include_eq_x_exclude_eq_x      FOR TESTING RAISING cx_static_check.
    METHODS lt                             FOR TESTING RAISING cx_static_check.
    METHODS lt_exclude_eq                  FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_swels DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS trace_active_forever       FOR TESTING RAISING cx_static_check.
    METHODS trace_deactivated_in_hours FOR TESTING RAISING cx_static_check.
    METHODS trace_in_fact_inactive     FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_truncate_date_intervals DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS first_test FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS lth_swels DEFINITION FINAL CREATE PRIVATE FOR TESTING.
  PUBLIC SECTION.
    CLASS-METHODS get_active_message_for_time IMPORTING ir_date              TYPE zcl_range_to_intervals__date=>tr_date
                                                        ir_time              TYPE zcl_range_to_intervals__time=>tr_time
                                                        iv_now_date          TYPE d DEFAULT sy-datum
                                                        iv_now_time          TYPE t DEFAULT sy-uzeit
                                              RETURNING VALUE(g_limit_trace) TYPE string.
ENDCLASS.


CLASS ltc_get_intervals IMPLEMENTATION.
  METHOD empty_ranges_ie_all_dates_time.
    " WHEN the intervals are calculated for empty date and time ranges (i.e. all dates and times)
    DATA(converter) = NEW zcl_range_to_intervals__dattim( ir_date = VALUE #( )
                                                          ir_time = VALUE #( ) ).
    DATA(intervals) = converter->get_contiguous_intervals( start_date = '00010101'
                                                           end_date   = '99991231' ).
    " THEN one interval is obtained from 01/01/0001 00:00:00 to 31/12/9999 23:59:59
    cl_abap_unit_assert=>assert_equals(
        act = intervals
        exp = VALUE zcl_range_to_intervals__dattim=>tt_interval( ( from_date      = '00010101'
                                                                   from_time      = '000000'
                                                                   from_date_time = '00010101000000'
                                                                   to_date        = '99991231'
                                                                   to_time        = '235959'
                                                                   to_date_time   = '99991231235959'
                                                                   is_in_range    = abap_true ) ) ).
  ENDMETHOD.

  METHOD include_eq_x_exclude_eq_x.
    " WHEN the same date is both included and excluded, and the same time is included and excluded
    DATA(converter) = NEW zcl_range_to_intervals__dattim( ir_date = VALUE #( option = 'EQ'
                                                                             low    = '20251204'
                                                                             ( sign = 'I' )
                                                                             ( sign = 'E' ) )
                                                          ir_time = VALUE #( option = 'EQ'
                                                                             low    = '151700'
                                                                             ( sign = 'I' )
                                                                             ( sign = 'E' ) ) ).
    DATA(intervals) = converter->get_contiguous_intervals( start_date = '00010101'
                                                           end_date   = '99991231' ).
    " THEN it's like empty ranges, one interval is obtained from 01/01/0001 00:00:00 to 31/12/9999 23:59:59
    cl_abap_unit_assert=>assert_equals( act = intervals
                                        exp = VALUE zcl_range_to_intervals__dattim=>tt_interval(
                                                        ( from_date      = '00010101'
                                                          from_time      = '000000'
                                                          from_date_time = '00010101000000'
                                                          to_date        = '99991231'
                                                          to_time        = '235959'
                                                          to_date_time   = '99991231235959'
                                                          is_in_range    = abap_false ) ) ).
  ENDMETHOD.

  METHOD lt.
    " WHEN the intervals are calculated for one date 04/12/2025, from 15:17:00 to 16:17:00
    "  BUT the intervals before 04/12/2025 are filtered out
    DATA(converter) = NEW zcl_range_to_intervals__dattim( ir_date = VALUE #( ( sign   = 'I'
                                                                               option = 'EQ'
                                                                               low    = '20251204' ) )
                                                          ir_time = VALUE #( ( sign   = 'I'
                                                                               option = 'BT'
                                                                               low    = '151700'
                                                                               high   = '161700' ) ) ).
    DATA(intervals) = converter->get_contiguous_intervals( start_date = '20251204'
                                                           end_date   = '20251207' ).
    " THEN three intervals are obtained:
    "      - from 01/01/0001 00:00:00 to 04/12/2025 15:16:59
    "      - from 04/12/2025 15:17:00 to 04/12/2025 16:17:00
    "      - from 04/12/2025 16:17:01 to 07/12/2025 23:59:59
    cl_abap_unit_assert=>assert_equals(
        act = intervals
        exp = VALUE zcl_range_to_intervals__dattim=>tt_interval( from_date = '20251204'
                                                                 ( from_time      = '000000'
                                                                   from_date_time = '20251204000000'
                                                                   to_date        = '20251204'
                                                                   to_time        = '151659'
                                                                   to_date_time   = '20251204151659'
                                                                   is_in_range    = abap_false )
                                                                 ( from_time      = '151700'
                                                                   from_date_time = '20251204151700'
                                                                   to_date        = '20251204'
                                                                   to_time        = '161700'
                                                                   to_date_time   = '20251204161700'
                                                                   is_in_range    = abap_true )
                                                                 ( from_time      = '161701'
                                                                   from_date_time = '20251204161701'
                                                                   to_date        = '20251207'
                                                                   to_time        = '235959'
                                                                   to_date_time   = '20251207235959'
                                                                   is_in_range    = abap_false ) ) ).
  ENDMETHOD.

  METHOD lt_exclude_eq.
    DATA(converter) = NEW zcl_range_to_intervals__dattim( ir_date = VALUE #( ( sign   = 'I'
                                                                               option = 'LT'
                                                                               low    = '20251204' )
                                                                             ( sign   = 'E'
                                                                               option = 'EQ'
                                                                               low    = '20241231' ) )
                                                          ir_time = VALUE #( ) ).
    DATA(intervals) = converter->get_contiguous_intervals( start_date = '00010101'
                                                           end_date   = '99991231' ).
    " THEN
    cl_abap_unit_assert=>assert_equals( act = intervals
                                        exp = VALUE zcl_range_to_intervals__dattim=>tt_interval(
                                                        from_time = '000000'
                                                        to_time   = '235959'
                                                        ( from_date      = '00010101'
                                                          from_date_time = '00010101000000'
                                                          to_date        = '20241230'
                                                          to_date_time   = '20241230235959'
                                                          is_in_range    = abap_true )
                                                        ( from_date      = '20241231'
                                                          from_date_time = '20241231000000'
                                                          to_date        = '20241231'
                                                          to_date_time   = '20241231235959'
                                                          is_in_range    = abap_false )
                                                        ( from_date      = '20250101'
                                                          from_date_time = '20250101000000'
                                                          to_date        = '20251203'
                                                          to_date_time   = '20251203235959'
                                                          is_in_range    = abap_true )
                                                        ( from_date      = '20251204'
                                                          from_date_time = '20251204000000'
                                                          to_date        = '99991231'
                                                          to_date_time   = '99991231235959'
                                                          is_in_range    = abap_false ) ) ).
  ENDMETHOD.
ENDCLASS.


CLASS ltc_swels IMPLEMENTATION.
  METHOD trace_active_forever.
    cl_abap_unit_assert=>assert_equals( act = lth_swels=>get_active_message_for_time( ir_date     = VALUE #( )
                                                                                      ir_time     = VALUE #( )
                                                                                      iv_now_date = '20251123'
                                                                                      iv_now_time = '195050' )
                                        exp = `Trace active forever, till deactivated manually` ).
  ENDMETHOD.

  METHOD trace_deactivated_in_hours.
    cl_abap_unit_assert=>assert_equals(
        act = lth_swels=>get_active_message_for_time(
                  ir_date     = VALUE #( ( sign = 'I' option = 'EQ' low = '20251123' ) )
                  ir_time     = VALUE #( ( sign = 'I' option = 'BT' low = '183400' high = '193400' ) )
                  iv_now_date = '20251123'
                  iv_now_time = '190000' )
        exp = |Trace deactivated in 00:34:00 hours| ).
  ENDMETHOD.

  METHOD trace_in_fact_inactive.
    cl_abap_unit_assert=>assert_equals(
        act = lth_swels=>get_active_message_for_time(
                  ir_date     = VALUE #( ( sign = 'I' option = 'EQ' low = '20251123' ) )
                  ir_time     = VALUE #( ( sign = 'I' option = 'BT' low = '183400' high = '193400' ) )
                  iv_now_date = '20251123'
                  iv_now_time = '195050' )
        exp = `Trace in fact INACTIVE, now and forever, due to date/time restrictions` ).
  ENDMETHOD.
ENDCLASS.


CLASS ltc_truncate_date_intervals IMPLEMENTATION.
  METHOD first_test.
    cl_abap_unit_assert=>assert_equals( act = zcl_range_to_intervals__dattim=>truncate_date_intervals(
                                                  it_date_interval = VALUE #( ( from        = '00010101'
                                                                                to          = '20251231'
                                                                                is_in_range = abap_false )
                                                                              ( from        = '20260101'
                                                                                to          = '99991231'
                                                                                is_in_range = abap_true ) )
                                                  ir_filter_date   = VALUE #( ( sign   = 'I'
                                                                                option = 'GE'
                                                                                low    = '20251206' ) ) )
                                        exp = VALUE zcl_range_to_intervals__date=>tt_interval( ( from        = '20251206'
                                                                                                 to          = '20251231'
                                                                                                 is_in_range = abap_false )
                                                                                               ( from        = '20260101'
                                                                                                 to          = '99991231'
                                                                                                 is_in_range = abap_true ) ) ).
  ENDMETHOD.
ENDCLASS.


CLASS lth_swels IMPLEMENTATION.
  METHOD get_active_message_for_time.
    "! Theoretically, GET_INTERVALS may
    DATA local_date_assumed_forever TYPE d.

    DATA(range_to_intervals) = NEW zcl_range_to_intervals__dattim( ir_date = ir_date
                                                                   ir_time = ir_time ).
    local_date_assumed_forever = EXACT d( iv_now_date + 4 ).
    DATA(lt_date_time_interval) = range_to_intervals->get_contiguous_intervals( start_date = iv_now_date
                                                                                end_date   = local_date_assumed_forever ).

    CONVERT DATE iv_now_date
            TIME iv_now_time
            INTO TIME STAMP DATA(lv_now_date_time)
            TIME ZONE '      '.

    LOOP AT lt_date_time_interval REFERENCE INTO DATA(ls_date_time_interval)
         WHERE     from_date_time <= lv_now_date_time
               AND to_date_time   >= lv_now_date_time.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    IF ls_date_time_interval->is_in_range = abap_true.
      IF ls_date_time_interval->to_date_time = |{ local_date_assumed_forever }235959|.
        g_limit_trace = |Trace active forever, till deactivated manually|.
      ELSE.
        CONVERT DATE iv_now_date
                TIME iv_now_time
                INTO TIME STAMP DATA(lv_now_timestamp_utc)
                TIME ZONE '      '.
        g_limit_trace = |Trace deactivated in { CONV t( cl_abap_tstmp=>subtract( tstmp1 = ls_date_time_interval->to_date_time
                                                                                 tstmp2 = lv_now_timestamp_utc ) )
                                                TIME = USER
                        } hours|.
      ENDIF.
    ELSE.
      g_limit_trace = 'Trace in fact INACTIVE, now and forever, due to date/time restrictions'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
