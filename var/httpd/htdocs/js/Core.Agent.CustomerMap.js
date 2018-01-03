// --
// Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

var Core = Core || {};
Core.Agent = Core.Agent || {};

/**
 * @namespace
 * @exports TargetNS as Core.Agent.CustomerMap
 * @description
 *      This namespace contains the special module functions for the CustomerMap.
 */
Core.Agent.CustomerMap = (function (TargetNS) {
    /**
     * @function
     * @return nothing
     *      This function initializes the special module functions
     */
    TargetNS.map;
    TargetNS.geocoder;
    TargetNS.Markers = [];

    TargetNS.Init = function (lat, lng, zoom) {
    /*global google:true*/
    /*eslint no-unused-vars: [2, {"args": "after-used", "varsIgnorePattern": "(UpdateTimeout|markerCluster)"}]*/
        var latlng = new google.maps.LatLng(lat, lng),
            UpdateTimeout,
            Options = {
                zoom: zoom,
                center: latlng,
                mapTypeId: google.maps.MapTypeId.ROADMAP
            };

        TargetNS.geocoder = new google.maps.Geocoder();

        TargetNS.map = new google.maps.Map(
            document.getElementById("map_canvas"),
            Options
       );

        // update latest map position
        google.maps.event.addListener(TargetNS.map, 'zoom_changed', function() {
            TargetNS.Update(TargetNS.map);
        });
        google.maps.event.addListener(TargetNS.map, 'dragend', function() {
            TargetNS.Update(TargetNS.map);
        });

        TargetNS.Fetch()
    };

    TargetNS.Update = function () {
        var UpdateTimeout;
        window.clearTimeout(UpdateTimeout);
        UpdateTimeout = window.setTimeout(function () {
            var zoomLevel = TargetNS.map.getZoom();
            var Center = TargetNS.map.getCenter();

            Core.AJAX.FunctionCall(
                Core.Config.Get('Baselink'),
                'Action=AgentCustomerMap&Subaction=Update;Zoom=' + zoomLevel + ';Latitude=' + Center.lat() + ';Longitude=' + Center.lng(),
                function() {},
                'json'
            );
        }, 500);
    }
    TargetNS.Fetch = function () {
        Core.AJAX.FunctionCall(
            Core.Config.Get('Baselink'),
            'Action=AgentCustomerMap&Subaction=Data',
            function (Data) {
                if (!Data) {
                    alert("ERROR: Invalid JSON: " + Data);
                }
                else {
                    var DataH = new Array();
                    var DataV = new Array();
                    var Size  = 0.00001;
                    for (var F=0;F<Data.length;F++) {
                        if (DataV[Data[F][0]] && DataH[Data[F][1]]) {
                            DataV[Data[F][0]] = Number(DataV[Data[F][0]]) + Number(Size);
                            DataH[Data[F][1]] = Number(DataH[Data[F][1]]) + Number(Size);
                        }
                        else {
                            DataV[Data[F][0]] = Number(Size);
                            DataH[Data[F][1]] = Number(Size);
                        }
                        Data[F][0] = Number(Data[F][0]) + Number(DataV[Data[F][0]]);
                        Data[F][1] = Number(Data[F][1]) + Number(DataH[Data[F][1]]);

                        TargetNS.Marker(Data[F][0], Data[F][1], Data[F][2], Data[F][3]);
                    }
                }
                /*global MarkerClusterer:true*/
                var markerCluster = new MarkerClusterer(TargetNS.map, TargetNS.Markers,
                    {
                        imagePath: '../Znuny4OTRSCustomerMap/m'
                    }
                );
            },
            'json'
       );
    }

    TargetNS.Marker = function (Lat, Lng, Key, Count){
        var Image, zIndex;
        if (Count > 0) {
            zIndex = 1000;
            Image = "http://www.google.com/mapfiles/marker.png";
        }
        else {
            zIndex = -1000;
            Image = "http://www.google.com/mapfiles/dd-start.png";
        }
        var latlng = new google.maps.LatLng(Lat, Lng);
        var marker = new google.maps.Marker({ map: TargetNS.map, position: latlng, icon: Image, title: Key, zIndex: zIndex });
        google.maps.event.addListener(marker, 'click', function() {
            Core.AJAX.FunctionCall(
                Core.Config.Get('Baselink'),
                'Action=AgentCustomerMap&Subaction=Customer;Login=' + Key,
                function (ObjectRef) {
                    if (!ObjectRef) {
                        alert("ERROR: Invalid JSON: " + ObjectRef);
                    }
                    else {
                        var Name    = '<b>' + ObjectRef['UserFirstname'] + ' ' + ObjectRef['UserLastname'] + '</b>';
                        var Address = ObjectRef['UserStreet'] + ' ' + ObjectRef['UserCity'] + ' ' + ObjectRef['UserCountry'];
                        var Content = Name;
                        Content = Content + '<font size="-2">'
                        if (ObjectRef['UserCompany']) {
                            Content = Content + '<br/>' + '(' + ObjectRef['UserCompany'] + ')';
                        }
                        if (ObjectRef['CustomerCompanyName']) {
                            Content = Content + '<br/>' + '(' + ObjectRef['CustomerCompanyName'] + ')';
                        }
                        if (ObjectRef['UserPhone']) {
                            Content = Content + '<br/>' +  ObjectRef['UserPhone'];
                        }
                        if (Address) {
                            Content = Content + '<br/>' +  Address;
                        }
                        Content = Content + '</font>';
                        var infowindow = new google.maps.InfoWindow();
                        infowindow.setContent(Content);
                        infowindow.open(TargetNS.map, marker);
                    }
                },
                'json'
            );
        });
        TargetNS.Markers.push(marker);
    };
    return TargetNS;
}(Core.Agent.CustomerMap || {}));
