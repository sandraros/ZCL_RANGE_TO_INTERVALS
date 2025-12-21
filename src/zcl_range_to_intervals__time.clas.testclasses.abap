*"* use this source file for your ABAP unit test classes

CLASS ltc_time_range DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS all           FOR TESTING RAISING cx_static_check.
    METHODS include_eq_X_exclude_eq_x FOR TESTING RAISING cx_static_check.
    METHODS lt            FOR TESTING RAISING cx_static_check.
    METHODS lt_exclude_eq FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_time_range IMPLEMENTATION.
  METHOD all.
    DATA(lo_time_range) = NEW zcl_range_to_intervals__time( VALUE #( ) ).
    cl_abap_unit_assert=>assert_equals(
        act = lo_time_range->get_intervals( )
        exp = VALUE zcl_range_to_intervals__time=>tt_interval( ( from = '000000' to = '235959' is_in_range = abap_true ) ) ).
  ENDMETHOD.

  METHOD include_eq_X_exclude_eq_x.
    DATA(lo_time_range) = NEW zcl_range_to_intervals__time( VALUE #( ( sign = 'I' option = 'EQ' low = '151712' )
                                                       ( sign = 'E' option = 'EQ' low = '151712' ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = lo_time_range->get_intervals( )
        exp = VALUE zcl_range_to_intervals__time=>tt_interval( ( from = '000000' to = '235959' is_in_range = abap_false ) ) ).
  ENDMETHOD.

  METHOD lt.
    DATA(lo_time_range) = NEW zcl_range_to_intervals__time( VALUE #( ( sign = 'I' option = 'LT' low = '151712' ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = lo_time_range->get_intervals( )
        exp = VALUE zcl_range_to_intervals__time=>tt_interval( ( from = '000000' to = '151711' is_in_range = abap_true )
                                                 ( from = '151712' to = '235959' is_in_range = abap_false ) ) ).
  ENDMETHOD.

  METHOD lt_exclude_eq.
    DATA(lo_time_range) = NEW zcl_range_to_intervals__time( VALUE #( ( sign = 'I' option = 'LT' low = '151712' )
                                                       ( sign = 'E' option = 'EQ' low = '123000' ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = lo_time_range->get_intervals( )
        exp = VALUE zcl_range_to_intervals__time=>tt_interval( ( from = '000000' to = '122959' is_in_range = abap_true )
                                                 ( from = '123000' to = '123000' is_in_range = abap_false )
                                                 ( from = '123001' to = '151711' is_in_range = abap_true )
                                                 ( from = '151712' to = '235959' is_in_range = abap_false ) ) ).
  ENDMETHOD.
ENDCLASS.
