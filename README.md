# ZCL_RANGE_TO_INTERVALS
Convert a range into intervals (ABAP).

`ZCL_RANGE_TO_INTERVALS` is a facade class which invokes type-dependent classes: 
- `ZCL_RANGE_TO_INTERVALS__DATE`
- `ZCL_RANGE_TO_INTERVALS__TIME`

The repository also comes with the class `ZCL_RANGE_TO_INTERVALS__DATTIM` which processes Date and Time [Ranges Tables](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/abenranges_table_glosry.html) ("type range of").

IMPORTANT: these classes have been created for one very rare usage, I don't see other usages for now, probably it's not the classes you are looking for.

Description of the only known usage:
- Situation:
  - In the transaction `SWELS`, the trace can be activated.
  - It's active by default for one hour (the end time is stored in a time Ranges Table).
  - After one hour, although `SWELS` shows that the trace is active, practically it's not because the end time has passed.
  - It's misleading because the end time can be seen only in a separate screen.
  - Note that instead of using the time interval, it can be manually changed in the separate screen.
- How it can be improved, how `ZCL_RANGE_TO_INTERVALS__DATTIM` can help:
  - In the first screen, it should be shown a clear information when the trace is active:
    - "Trace deactivated in 00:17:20 hours" (in 17 minutes)
    - "Trace NOW inactive due to date/time restrictions" (use Switch off and Switch on to reactivate the trace for one hour)
    - "Trace active forever, till deactivated manually" (situation when the date and time intervals have been removed manually, no intervals = always valid)
  - **Because the date and time intervals are defined as Ranges Tables, it's theoretically possible to enter complex conditions in the Ranges Tables (e.g. any time except before 07:00:00 and after 21:00:00).**
  - `ZCL_RANGE_TO_INTERVALS__DATTIM` can be used to convert a Ranges Table into intervals, it's then simple to know if the interval for now is in the interval. The test class `LTC_SWELS` contains the demonstration.
 
Simple case how `ZCL_RANGE_TO_INTERVALS__DATTIM` can be used (excerpt from the provided test classes):
```abap
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
    "      - from 04/12/2025 00:00:00 to 04/12/2025 15:16:59, which is outside the interval
    "      - from 04/12/2025 15:17:00 to 04/12/2025 16:17:00, which is inside the interval
    "      - from 04/12/2025 16:17:01 to 07/12/2025 23:59:59, which is outside the interval
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
```
