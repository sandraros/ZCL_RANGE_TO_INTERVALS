*"* use this source file for your ABAP unit test classes

CLASS ltc_time_range DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS all FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_time_range IMPLEMENTATION.
  METHOD all.
    " GIVEN
    DATA(lr_time_range) = VALUE zcl_range_to_intervals__time=>tr_time( ( sign = 'I' option = 'LT' low = '151712' ) ).
    DATA(lt_time_interval) = VALUE zcl_range_to_intervals__time=>tt_interval( ).

    " WHEN
    zcl_range_to_intervals=>convert( EXPORTING ranges_table = lr_time_range
                                     IMPORTING intervals        = lt_time_interval ).

    " THEN
    cl_abap_unit_assert=>assert_equals( act = lt_time_interval
                                        exp = VALUE zcl_range_to_intervals__time=>tt_interval(
                                                        ( from = '000000' to = '151711' is_in_range = abap_true )
                                                        ( from = '151712' to = '235959' is_in_range = abap_false ) ) ).
  ENDMETHOD.
ENDCLASS.
