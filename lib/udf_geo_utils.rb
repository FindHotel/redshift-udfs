class UdfGeoUtils
  UDFS = [
      {
          type:        :function,
          name:        :haversine,
          description: "Calculate the great circle distance between two points on the earth",
          params:      "lon1 float, lat1 float, lon2 float, lat2 float",
          return_type: "bigint",
          body:        %~

            from math import radians, cos, sin, asin, sqrt

            # Credit:
            # https://stackoverflow.com/a/15737218

            if lon1 is None or lat1 is None or lon2 is None or lat2 is None:
              return

            # convert decimal degrees to radians
            lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
            # haversine formula
            dlon = lon2 - lon1
            dlat = lat2 - lat1
            a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
            c = 2 * asin(sqrt(a))
            km = 6367 * c
            return km

          ~,
          tests: [
              {query: "select ?(50, 70, 50, 70)", expect: '0', example: true},
              {query: "select ?(40.4168, 3.7038, 41.6488, 0.8891)", expect: '341', example: true},
              {query: "select ?(52.3702, 4.8952, 41.6488, 0.8891)", expect: '1270', example: true},
          ]
      }
  ]
end
