CLASS zcx_range_to_intervals DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS cp_and_np_not_supported TYPE sotr_conc VALUE '0050568A5B6D02DE96DB1BE3290F9BD0' ##NO_TEXT.
    CONSTANTS invalid_option          TYPE sotr_conc VALUE '0050568E52B002EE9598FF74E3A00789' ##NO_TEXT.
    CONSTANTS invalid_ranges_table    TYPE sotr_conc VALUE '005056A501951ED3B1C16BA2948C12EC' ##NO_TEXT.
    CONSTANTS base_type_not_supported TYPE sotr_conc VALUE '00145EF41CBA02DD9B9ED649043FC3E7' ##NO_TEXT.
    " CONSTANTS  TYPE sotr_conc VALUE '0050568E52B002EE929DA821105645F4' ##NO_TEXT.
    " CONSTANTS  TYPE sotr_conc VALUE '0050568E52B002EE929DA82337EA05F5' ##NO_TEXT.
    " CONSTANTS  TYPE sotr_conc VALUE '0050568E52B002EE929DA825AF2F05F6' ##NO_TEXT.
    " CONSTANTS  TYPE sotr_conc VALUE '0050568A5B6D02EE96DB40B5876E8835' ##NO_TEXT.

    METHODS constructor
      IMPORTING textid    LIKE textid            OPTIONAL
                !previous LIKE previous          OPTIONAL
                !option   TYPE rsdsselopt-option OPTIONAL.

    METHODS get_text REDEFINITION.

  PRIVATE SECTION.
    DATA option TYPE rsdsselopt-option.

    METHODS get_message_with_variables
      IMPORTING !message      TYPE csequence
                msgv1         TYPE csequence OPTIONAL
                msgv2         TYPE csequence OPTIONAL
                msgv3         TYPE csequence OPTIONAL
                msgv4         TYPE csequence OPTIONAL
      RETURNING VALUE(result) TYPE string.
ENDCLASS.


CLASS zcx_range_to_intervals IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( textid   = textid
                        previous = previous ).
    me->option = option.
  ENDMETHOD.

  METHOD get_text.
    CASE textid.
      WHEN cp_and_np_not_supported.
        result = 'The options CP and NP are currently not supported by ZCL_RANGE_TO_INTERVALS'(001).
      WHEN invalid_option.
        result = get_message_with_variables( message = 'The option &1 is invalid'(002)
                                             msgv1   = option ).
      WHEN invalid_option.
        result = 'Invalid ranges table (internal table with lines of components SIGN 1c, OPTION 2c, LOW anytype, HIGH anytype, LOW and HIGH same type)'(003).
      WHEN base_type_not_supported.
        result = 'Base type of ranges table currently not supported (current support: date, time)'(004).
    ENDCASE.
  ENDMETHOD.

  METHOD get_message_with_variables.
    result = message.
    REPLACE ALL OCCURRENCES OF '&1' IN result WITH msgv1.
    REPLACE ALL OCCURRENCES OF '&2' IN result WITH msgv2.
    REPLACE ALL OCCURRENCES OF '&3' IN result WITH msgv3.
    REPLACE ALL OCCURRENCES OF '&4' IN result WITH msgv4.
  ENDMETHOD.
ENDCLASS.
