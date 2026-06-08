package com.argusx.compliance.model;

/** Coordinate contract used by the Null Object pattern (Lab 8). */
public interface Coordinates {
    boolean isNull();
    double getLat();
    double getLng();
    String describe();
}
