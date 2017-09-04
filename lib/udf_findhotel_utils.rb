class UdfFindhotelUtils
  UDFS = [
      {
          type:        :function,
          name:        :parse_room_description,
          description: "Returns number of rooms, adults or children with respect to given input component.",
          params:      "component varchar(max), room varchar(max)",
          return_type: "integer",
          body:        %~

            import logging
            logger = logging.getLogger('parse_room_description')

            if not room:
              return None
            else:
              try:
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
              except (ValueError, IndexError) as e:
                logger.error("Error: " + str(e) + " - Invalid room query " + str(room))
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
      },
      {
          type:        :function,
          name:        :make_bing_click_batch_id,
          description: "Returns a unique identifier for a batch of clicks reported by Bing.",
          params:      "ad_group_id bigint, ad_id bigint, keyword varchar(max), device_type varchar(max), network varchar(max), bid_match_type varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            import hashlib
            import json

            key = {
                "ad_group_id": ad_group_id,
                "ad_id": ad_id,
                "keyword": keyword,
                "device_type": device_type,
                "network": network,
                "bid_match_type": bid_match_type}

            m = hashlib.md5()
            m.update(json.dumps(key, sort_keys=True))
            return m.hexdigest()

          ~,
          tests:       [
                           {query: "select ?(1, 2, '3', 'mobile', 'a', 'b')", expect: '3e301133b2ab7a2906465840b8a7761e' , example: true},
                           {query: "select ?(3, 2, '1', 'mobile', 'a', 'b')", expect: '06d3d49eccf6276a033ad97a166775d0' , example: true},
                           {query: "select ?(1, 2, '3', 'mobile', 'b', 'a')", expect: '7aedf2639ae096c416fc4077e5768cda' , example: true},
                       ]
      }
    ]
end
