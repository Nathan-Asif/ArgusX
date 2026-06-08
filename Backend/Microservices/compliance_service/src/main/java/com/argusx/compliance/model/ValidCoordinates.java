package com.argusx.compliance.model;

public class ValidCoordinates implements Coordinates {

    private final double lat;
    private final double lng;

    public ValidCoordinates(double lat, double lng) {
        this.lat = lat;
        this.lng = lng;
    }

    @Override
    public boolean isNull() {
        return false;
    }

    @Override
    public double getLat() {
        return lat;
    }

    @Override
    public double getLng() {
        return lng;
    }

    @Override
    public String describe() {
        return String.format("(%.5f, %.5f)", lat, lng);
    }
}
