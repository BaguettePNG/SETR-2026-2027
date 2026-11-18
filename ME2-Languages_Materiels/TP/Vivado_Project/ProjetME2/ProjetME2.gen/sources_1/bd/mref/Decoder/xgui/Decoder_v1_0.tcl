# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ADDR_SELECT" -parent ${Page_0}


}

proc update_PARAM_VALUE.ADDR_SELECT { PARAM_VALUE.ADDR_SELECT } {
	# Procedure called to update ADDR_SELECT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_SELECT { PARAM_VALUE.ADDR_SELECT } {
	# Procedure called to validate ADDR_SELECT
	return true
}


proc update_MODELPARAM_VALUE.ADDR_SELECT { MODELPARAM_VALUE.ADDR_SELECT PARAM_VALUE.ADDR_SELECT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_SELECT}] ${MODELPARAM_VALUE.ADDR_SELECT}
}

