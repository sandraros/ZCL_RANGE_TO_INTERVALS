*"* use this source file for your ABAP unit test classes

CLASS ltcl_ DEFINITION dEFERRED.
class zcl_range_to_intervals__dattim definition local friends ltcl_.

CLASS ltc_dattim_range DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS all                       FOR TESTING RAISING cx_static_check.
    METHODS include_eq_x_exclude_eq_x FOR TESTING RAISING cx_static_check.
    METHODS lt                        FOR TESTING RAISING cx_static_check.
    METHODS lt_exclude_eq             FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_dattim_range IMPLEMENTATION.
  METHOD all.
    DATA(lo_converter) = NEW zcl_range_to_intervals__dattim( ir_date = VALUE #( )
                                                             ir_time = VALUE #( ) ).
    cl_abap_unit_assert=>assert_equals( act = lo_converter->get_intervals( )
                                        exp = VALUE zcl_range_to_intervals__dattim=>tt_interval( ( from_date   = '00010101'
                                                                                                   from_time   = '000000'
                                                                                                   to_date     = '99991231'
                                                                                                   to_time     = '235959'
                                                                                                   is_in_range = abap_true ) ) ).
  ENDMETHOD.

  METHOD include_eq_x_exclude_eq_x.
    DATA(lo_date_range) = NEW zcl_range_to_intervals__dattim( ir_date = VALUE #( option = 'EQ'
                                                                                 low    = '20251204'
                                                                                 ( sign = 'I' )
                                                                                 ( sign = 'E' ) )
                                                              ir_time = VALUE #( option = 'EQ'
                                                                                 low    = '151700'
                                                                                 ( sign = 'I' )
                                                                                 ( sign = 'E' ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = lo_date_range->get_intervals( )
        exp = VALUE zcl_range_to_intervals__dattim=>tt_interval(
                  ( from_date = '00010101' from_time = '000000' to_date = '99991231' to_time = '235959' is_in_range = abap_false ) ) ).
  ENDMETHOD.

  METHOD lt.
    DATA(lo_date_range) = NEW zcl_range_to_intervals__dattim( ir_date = VALUE #( ( sign = 'I' option = 'EQ' low = '20251204' ) )
                                                              ir_time = VALUE #( ( sign = 'I' option = 'BT' low = '151700' high = '161700' ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = lo_date_range->get_intervals( ir_filter_date = VALUE #( ( sign = 'I' option = 'GE' low = '20251204' ) ) )
        exp = VALUE zcl_range_to_intervals__dattim=>tt_interval(
                  ( from_date = '20251204' from_time = '000000' to_date = '20251204' to_time = '151659' is_in_range = abap_false )
                  ( from_date = '20251204' from_time = '151700' to_date = '20251204' to_time = '161700' is_in_range = abap_true )
                  ( from_date = '20251204' from_time = '161701' to_date = '20251207' to_time = '151659' is_in_range = abap_false ) ) ).
  ENDMETHOD.

  METHOD lt_exclude_eq.
    DATA(lo_date_range) = NEW zcl_range_to_intervals__dattim( ir_date = VALUE #( ( sign = 'I' option = 'LT' low = '20251204' )
                                                                                 ( sign = 'E' option = 'EQ' low = '20241231' ) )
                                                              ir_time = VALUE #( ) ).
    cl_abap_unit_assert=>assert_equals(
        act = lo_date_range->get_intervals( )
        exp = VALUE zcl_range_to_intervals__dattim=>tt_interval(
                        from_time = '000000'
                        to_time   = '235959'
                        ( from_date = '00010101' to_date = '20241230' is_in_range = abap_true )
                        ( from_date = '20241231' to_date = '20241231' is_in_range = abap_false )
                        ( from_date = '20250101' to_date = '20251203' is_in_range = abap_true )
                        ( from_date = '20251204' to_date = '99991231' is_in_range = abap_false ) ) ).
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_ DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS first_test FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_ IMPLEMENTATION.
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
