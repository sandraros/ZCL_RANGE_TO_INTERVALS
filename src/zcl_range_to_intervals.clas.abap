CLASS zcl_range_to_intervals DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! <p class="shorttext synchronized" lang="en"></p>
    "!
    "! @parameter ranges_table | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter intervals | <p class="shorttext synchronized" lang="en"></p>
    "! @raising zcx_range_to_intervals | <p class="shorttext synchronized" lang="en"></p>
    "! Possible exceptions:<ul>
    "! <li>Parameter RANGES_TABLE doesn't contain a Ranges Table</li>
    "! </ul>
    CLASS-METHODS convert
      IMPORTING ranges_table TYPE STANDARD TABLE
      EXPORTING !intervals   TYPE SORTED TABLE
      RAISING   zcx_range_to_intervals.

  PRIVATE SECTION.
    CLASS-METHODS get_ranges_table_base_type
      IMPORTING rtti             TYPE REF TO cl_abap_typedescr
      RETURNING VALUE(base_type) TYPE REF TO cl_abap_typedescr.

    CLASS-METHODS is_ranges_table
      IMPORTING rtti            TYPE REF TO cl_abap_typedescr
      RETURNING VALUE(is_range) TYPE abap_bool.

    CLASS-METHODS is_ranges_table_line
      IMPORTING rtti                 TYPE REF TO cl_abap_typedescr
      RETURNING VALUE(is_range_line) TYPE abap_bool.
ENDCLASS.


CLASS zcl_range_to_intervals IMPLEMENTATION.
  METHOD convert.
    DATA(lo_ranges_table_typedescr) = cl_abap_typedescr=>describe_by_data( ranges_table ).
    IF abap_false = is_ranges_table( lo_ranges_table_typedescr ).
      RAISE EXCEPTION TYPE zcx_range_to_intervals
        EXPORTING
          textid = zcx_range_to_intervals=>invalid_ranges_table.
    ENDIF.

    DATA(lo_ranges_table_base_type) = get_ranges_table_base_type( lo_ranges_table_typedescr ).
    CASE lo_ranges_table_base_type->type_kind.
      WHEN lo_ranges_table_base_type->typekind_date.
        DATA(lo_date_converter) = NEW zcl_range_to_intervals__date( ranges_table ).
        intervals = lo_date_converter->get_intervals( ).
      WHEN lo_ranges_table_base_type->typekind_time.
        DATA(lo_time_converter) = NEW zcl_range_to_intervals__time( ranges_table ).
        intervals = lo_time_converter->get_intervals( ).
      WHEN OTHERS.
        RAISE EXCEPTION TYPE zcx_range_to_intervals
          EXPORTING
            textid = zcx_range_to_intervals=>base_type_not_supported.
    ENDCASE.
  ENDMETHOD.

  METHOD get_ranges_table_base_type.
    DATA rtti_tab TYPE REF TO cl_abap_tabledescr.
    DATA rtti_str TYPE REF TO cl_abap_structdescr.

    CLEAR base_type.

    rtti_tab ?= rtti.
    rtti_str ?= rtti_tab->get_table_line_type( ).

    DATA(low) = REF #( rtti_str->components[ 3 ] ).

    base_type = rtti_str->get_component_type( p_name = low->name ).
  ENDMETHOD.

  METHOD is_ranges_table.
    DATA rtti_tab  TYPE REF TO cl_abap_tabledescr.
    DATA rtti_line TYPE REF TO cl_abap_typedescr.

    TRY.
        " s'assurer que le type est un type de table
        rtti_tab ?= rtti.
        " récupérer le type de ligne du type de table
        rtti_line = rtti_tab->get_table_line_type( ).
        " s'assurer que le type de ligne est une ligne de range
        is_range = is_ranges_table_line( rtti_line ).
      CATCH cx_sy_move_cast_error.
        is_range = abap_false.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD is_ranges_table_line.
    DATA rtti_str TYPE REF TO cl_abap_structdescr.
    DATA lt_comp  TYPE cl_abap_structdescr=>component_table.

    FIELD-SYMBOLS <sign>   TYPE abap_componentdescr.
    FIELD-SYMBOLS <option> TYPE abap_componentdescr.
    FIELD-SYMBOLS <low>    TYPE abap_componentdescr.
    FIELD-SYMBOLS <high>   TYPE abap_componentdescr.

    is_range_line = abap_false.

    TRY.
        " s'assurer que le type est une structure
        rtti_str ?= rtti.
      CATCH cx_sy_move_cast_error.
        RETURN.
    ENDTRY.

    IF lines( rtti_str->components ) <> 4.
      RETURN.
    ENDIF.

    lt_comp = rtti_str->get_components( ).
    READ TABLE lt_comp INDEX 1 ASSIGNING <sign>.
    READ TABLE lt_comp INDEX 2 ASSIGNING <option>.
    READ TABLE lt_comp INDEX 3 ASSIGNING <low>.
    READ TABLE lt_comp INDEX 4 ASSIGNING <high>.

    IF    <sign>-name            <> 'SIGN'
       OR <sign>-type->type_kind <> cl_abap_typedescr=>typekind_char
       OR <sign>-type->length    <> 1 * cl_abap_char_utilities=>charsize.
      RETURN.
    ENDIF.

    IF    <option>-name            <> 'OPTION'
       OR <option>-type->type_kind <> cl_abap_typedescr=>typekind_char
       OR <option>-type->length    <> 2 * cl_abap_char_utilities=>charsize.
      RETURN.
    ENDIF.

    IF <low>-name <> 'LOW'.
      RETURN.
    ENDIF.

    IF <high>-name <> 'HIGH'.
      RETURN.
    ENDIF.

    IF <low>-type <> <high>-type.
      RETURN.
    ENDIF.

    is_range_line = abap_true.
  ENDMETHOD.
ENDCLASS.
