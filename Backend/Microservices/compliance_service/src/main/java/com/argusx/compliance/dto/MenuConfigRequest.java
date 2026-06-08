package com.argusx.compliance.dto;

public class MenuConfigRequest {

    private String riderId;
    private String requestType = "HUD_MENU_CONFIG";

    public String getRiderId() { return riderId; }
    public void setRiderId(String riderId) { this.riderId = riderId; }
    public String getRequestType() { return requestType; }
    public void setRequestType(String requestType) { this.requestType = requestType; }
}
