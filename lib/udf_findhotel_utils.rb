class UdfFindhotelUtils
  UDFS = [
      {
          type:        :function,
          name:        :parse_room_description,
          description: "Returns number of rooms, adults or children with respect to given input component.",
          params:      "component varchar(max), room varchar(max)",
          return_type: "integer",
          body:        %~
            if not room:
              return None
            else:
              adults = 0
              children = 0
              rooms = room.split('|')
              for r in rooms:
                ch = r.split(':')
                adults += int(ch[0])
                if len(ch) > 1:
                  children += len(ch[-1].split(','))

              if component.lower() == 'adults':
                return adults
              elif component.lower() == 'children':
                return children
              elif component.lower() == 'rooms':
                return len(rooms)
              else:
                return None

          ~,
          tests:       [
                           {query: "select ?('adults', '1|2')", expect: 3 , example: true},
                           {query: "select ?('Adults', '2')", expect: 2, example: true},
                           {query: "select ?('ADULTS', '2:0,0')", expect: 2, example: true},
                           {query: "select ?('adults', '2:0|1:2,6')", expect: 3, example: true},
                           {query: "select ?('adults', '')", expect: 0, example: true},
                           {query: "select ?('children', '1|2')", expect: 0 , example: true},
                           {query: "select ?('CHILDREN', '2')", expect: 0, example: true},
                           {query: "select ?('Children', '2:0,0')", expect: 2, example: true},
                           {query: "select ?('Children', '2:0|1:2,6')", expect: 3, example: true},
                           {query: "select ?('children', '2|1:12')", expect: 1, example: true},
                           {query: "select ?('rooms', '2|1:12')", expect: 2, example: true},
                           {query: "select ?('ROOMS', '2:0|1:2,6')", expect: 2, example: true},
                           {query: "select ?('rooms', '2:0|1:2,6|2')", expect: 3, example: true},
                           {query: "select ?('roomz', '2:0|1:2,6|2')", expect: nil, example: true},
                       ]
      },
      {
          type:        :function,
          name:        :make_adwords_click_batch_id,
          description: "Returns a unique identifier for a batch of clicks reported by Adwords.",
          params:      "ad_group_id bigint, ad_id bigint, criteria_id bigint, device varchar(max), ad_network_type1 varchar(max), ad_network_type2 varchar(max), click_type varchar(max), slot varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            import hashlib
            import json

            key = {
                "ad_group_id": ad_group_id,
                "ad_id": ad_id,
                "criteria_id": criteria_id,
                "device": device,
                "ad_network_type1": ad_network_type1,
                "ad_network_type2": ad_network_type2,
                "click_type": click_type,
                "slot": slot}

            m = hashlib.md5()
            m.update(json.dumps(key, sort_keys=True))
            return m.hexdigest()

          ~,
          tests:       [
                           {query: "select ?(1, 2, 3, 'mobile', 'a', 'b', 's', 'x')", expect: 'd95633497fddd300103c07903b65533b' , example: true},
                           {query: "select ?(3, 2, 1, 'mobile', 'a', 'b', 's', 'x')", expect: '78172d9b2a0d90cbff6160632e68449c' , example: true},
                           {query: "select ?(1, 2, 3, 'mobile', 'b', 'a', 'h', 'y')", expect: '65db6fc8ffebab864baff57c4a90d5db' , example: true},
                       ]
      }
    ]
end
