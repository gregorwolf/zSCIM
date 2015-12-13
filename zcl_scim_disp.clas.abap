class ZCL_SCIM_DISP definition
  public
  inheriting from Y_ADL_DISP_BASE
  create public .

public section.

  methods IF_HTTP_EXTENSION~HANDLE_REQUEST
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_SCIM_DISP IMPLEMENTATION.


  METHOD if_http_extension~handle_request.
    me->handler(
      EXPORTING
        p = '^/Users'
        h = 'ZCL_SCIM_USERS'
    ).
    me->dispatch( server = server ).
  ENDMETHOD.
ENDCLASS.