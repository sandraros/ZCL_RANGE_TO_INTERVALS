*"* use this source file for your ABAP unit test classes

CLASS ltc_date_range DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS empty_range_ie_all_dates           FOR TESTING RAISING cx_static_check.
    METHODS include_eq_X_exclude_eq_x FOR TESTING RAISING cx_static_check.
    METHODS lt            FOR TESTING RAISING cx_static_check.
    METHODS lt_exclude_eq FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_date_range IMPLEMENTATION.
  METHOD empty_range_ie_all_dates.
    cl_abap_unit_assert=>assert_equals(
        act = NEW zcl_range_to_intervals__date( VALUE #( ) )->get_intervals( )
        exp = VALUE zcl_range_to_intervals__date=>tt_interval(
                        ( from = '00010101' to = '99991231' is_in_range = abap_true ) ) ).
  ENDMETHOD.

  METHOD include_eq_x_exclude_eq_x.
    DATA(lo_date_range) = NEW zcl_range_to_intervals__date( VALUE #( option = 'EQ'
                                                                     low    = '20251204'
                                                                     ( sign = 'I' )
                                                                     ( sign = 'E' ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = lo_date_range->get_intervals( )
        exp = VALUE zcl_range_to_intervals__date=>tt_interval(
                        ( from = '00010101' to = '99991231' is_in_range = abap_false ) ) ).
  ENDMETHOD.

  METHOD lt.
    DATA(lo_date_range) = NEW zcl_range_to_intervals__date( VALUE #( ( sign = 'I' option = 'LT' low = '20251204' ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = lo_date_range->get_intervals( )
        exp = VALUE zcl_range_to_intervals__date=>tt_interval(
                        ( from = '00010101' to = '20251203' is_in_range = abap_true )
                        ( from = '20251204' to = '99991231' is_in_range = abap_false ) ) ).
  ENDMETHOD.

  METHOD lt_exclude_eq.
    DATA(lo_date_range) = NEW zcl_range_to_intervals__date( VALUE #( ( sign = 'I' option = 'LT' low = '20251204' )
                                                                     ( sign = 'E' option = 'EQ' low = '20241231' ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = lo_date_range->get_intervals( )
        exp = VALUE zcl_range_to_intervals__date=>tt_interval(
                        ( from = '00010101' to = '20241230' is_in_range = abap_true )
                        ( from = '20241231' to = '20241231' is_in_range = abap_false )
                        ( from = '20250101' to = '20251203' is_in_range = abap_true )
                        ( from = '20251204' to = '99991231' is_in_range = abap_false ) ) ).
  ENDMETHOD.
ENDCLASS.
