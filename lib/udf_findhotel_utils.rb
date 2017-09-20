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
                "ad_group_id": str(ad_group_id),
                "ad_id": str(ad_id),
                "criteria_id": str(criteria_id),
                "device": device,
                "ad_network_type1": ad_network_type1,
                "ad_network_type2": ad_network_type2,
                "click_type": click_type,
                "slot": slot}

            m = hashlib.md5()
            m.update(json.dumps(key, sort_keys=True).encode())
            return m.hexdigest()

          ~,
          tests:       [
                           {query: "select ?(1, 2, 3, 'mobile', 'a', 'b', 's', 'x')", expect: '6d62ff88938aacd26d2f30d4c1145033' , example: true},
                           {query: "select ?(3, 2, 1, 'mobile', 'a', 'b', 's', 'x')", expect: 'c257ec3177dcf59cfd14742ffab6ae16' , example: true},
                           {query: "select ?(1, 2, 3, 'mobile', 'b', 'a', 'h', 'y')", expect: '4f3e466c87b1093f4c4ecc0348a01d4f' , example: true},
                       ]
      },
      {
          type:        :function,
          name:        :make_bing_click_batch_id,
          description: "Returns a unique identifier for a batch of clicks reported by Bing.",
          params:      "ad_group_id bigint, ad_id bigint, keyword_id bigint, device_type varchar(max), network varchar(max), bid_match_type varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            import hashlib
            import json

            actual_network = "Syndicated" if network=="Syndicated search partners" else "Owned"

            key = {
                "adgid": str(ad_group_id),
                "adid": str(ad_id),
                "kwid": str(keyword_id),
                "dv": device_type,
                "nk": actual_network,
                "bmt": bid_match_type}

            m = hashlib.md5()
            m.update(json.dumps(key, sort_keys=True).encode())
            return m.hexdigest()

          ~,
          tests:       [
                           {query: "select ?(1, 2, 3, 'mobile', 'Syndicated search partners', 'b')", expect: '0b593cae9b6b4e680e84f4afdc2edfb4' , example: true},
                           {query: "select ?(3, 2, 1, 'mobile', 'AOL search', 'b')", expect: 'd70bc31fea1edaa832c7956f603ad564' , example: true},
                           {query: "select ?(1, 2, 3, 'mobile', 'Bing and Yahoo! search', 'a')", expect: 'b41877b3b9a596b7492ef17ba9b2f826' , example: true},
                       ]
      },
      {
          type:        :function,
          name:        :fix_bing_batch_key,
          description: "Fix batch key for Bing source, converting all the ids to string and getting the right adgid.",
          params:      "click_batch_key_str varchar(max), url varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            import json
            from urlparse import urlparse, parse_qs

            def _pick_last(qs):
                for k, v in qs.items():
                    if v:
                        qs[k] = v[-1]
                return qs

            def get_label_value(label, *keys):
                for key in keys:
                    value = label.get(key)
                    if value:
                        return value

            url = urlparse(url)
            qs = _pick_last(parse_qs(url.query))
            raw_label = qs.get("label") or qs.get("Label") or ""
            label = _pick_last(parse_qs(raw_label))

            click_batch_key = json.loads(click_batch_key_str)
            click_batch_key["kwid"] = str(click_batch_key["kwid"])
            click_batch_key["adgid"] = get_label_value(label, "adgid", "ad_group_id")

            return json.dumps(click_batch_key, sort_keys=True).encode()

          ~,
          tests:       [
                       ]
      },
      {
          type:        :function,
          name:        :parse_label_query_string,
          description: 'convert naked (without url) query string to json dict lifted from
                        https://github.com/awslabs/amazon-redshift-udfs/blob/master/scalar-udfs/f_parse_url_query_string.sql',
          params:      "url VARCHAR(MAX)",
          return_type: "varchar(max)",
          body:        %~
            from urlparse import urlparse, parse_qsl
            import json
            return json.dumps(dict(parse_qsl(urlparse(url)[2])))
          ~,
          tests:       [{query: "select parse_label_query_string('utf8=%E2%9C%93&query=redshift')", expect: '{"utf8": "\u2713", "query": "redshift"}' , example: true}]
      }
    ]
end
