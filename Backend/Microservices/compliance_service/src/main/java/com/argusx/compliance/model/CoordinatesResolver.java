package com.argusx.compliance.model;

import com.argusx.compliance.dto.CoordinatePayload;

/** Resolves inbound coordinate payloads to Valid or Null coordinate objects. */
public final class CoordinatesResolver {

    private CoordinatesResolver() {}

    public static Coordinates resolve(CoordinatePayload payload) {
        if (payload == null || payload.getLat() == null || payload.getLng() == null) {
            return NullCoordinates.INSTANCE;
        }
        double lat = payload.getLat();
        double lng = payload.getLng();
        if (lat == 0.0 && lng == 0.0) {
            return NullCoordinates.INSTANCE;
        }
        return new ValidCoordinates(lat, lng);
    }
}
