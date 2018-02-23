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
          name:        :make_adwords_keyword_click_batch_id,
          description: "Returns a unique identifier for a batch of clicks reported by Adwords Keyword Performance Report.",
          params:      "ad_group_id varchar(max), criteria_id bigint, device varchar(max), ad_network_type1 varchar(max), ad_network_type2 varchar(max), click_type varchar(max), slot varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            import hashlib
            import json

            key = {
                "ad_group_id": str(ad_group_id),
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
                           {query: "select ?('1', 3, 'mobile', 'a', 'b', 's', 'x')", expect: '4c4368a6e86fe648963d12b41f631479' , example: true},
                           {query: "select ?('3', 1, 'mobile', 'a', 'b', 's', 'x')", expect: 'c30f6870a961f3382a36397fe6106091' , example: true},
                           {query: "select ?('1', 3, 'mobile', 'b', 'a', 'h', 'y')", expect: 'ccc25ba0f417b68f24283fe9247b3c8a' , example: true},
                           {query: "select ?('1', 3, 'mobile', 'b', 'a', 'h', 'y')", expect: 'ccc25ba0f417b68f24283fe9247b3c8a' , example: true},
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
          name:        :make_im_click_batch_id,
          description: "Returns a unique identifier for a batch of clicks reported by Intent Media.",
          params:      "custom_dta varchar(max), campaign_tracking_code varchar(max), ad_group_tracking_code varchar(max), device varchar(max), destination varchar(max), publisher_segment varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            import hashlib
            import json

            key = {
                "custom_dta": custom_dta,
                "campaign_tracking_code": campaign_tracking_code,
                "ad_group_tracking_code": ad_group_tracking_code,
                "device": device,
                "destination": destination,
                "publisher_segment": publisher_segment}

            m = hashlib.md5()
            m.update(json.dumps(key, sort_keys=True).encode())
            return m.hexdigest()

          ~,
          tests:       [
                           {query: "select ?('dta31_60', 'UK_Hotels_Standard', 'CA_Low', 'DESKTOP', 'Amsterdam', '3146')", expect: '98eb9c159b8463b53deb6c7b16d88208', example: true},
                           {query: "select ?('dta_dateless', 'CA_Hotels_Standard', 'CA_Low', 'MOBILE', 'Castres', '3336')", expect: 'f0250a941177d91f4358607356581524', example: true},
                       ]
      },
      {
          type:        :function,
          name:        :qs_to_json,
          description: 'convert naked (without url) query string to json dict lifted from
                        https://github.com/awslabs/amazon-redshift-udfs/blob/master/scalar-udfs/f_parse_url_query_string.sql',
          params:      "url VARCHAR(MAX)",
          return_type: "varchar(max)",
          body:        %~
            from urlparse import urlparse, parse_qsl
            import json
            res = {}
            try:
              res = json.dumps(dict(parse_qsl(urlparse(url)[2])))
            except UnicodeDecodeError:
              res = '{"errored": "bad utf8 char detected in string"}'
            return res
          ~,
          tests:       [{query: "select qs_to_json('utf8=%E2%9C%93&query=redshift')", expect: '{"utf8": "\u2713", "query": "redshift"}' , example: true},
                        {query: "select qs_to_json('http://example.com?utf8=%E2%9C%93&query=redshift')", expect: '{}' , example: false},
                        {query: "select qs_to_json('codetype%3D2%26clicktype%3DA%26hotelid%3D2718240%26campaignid%3D21933%26adgroupid%3D112633958%26targetcode%3D78%26headlineid%3D142%26desclayoutid%3D1%26desclayoutvn%3D1%26se=bing%26ad_group_id=7005466028%26ad_id=83975210798524%26device=c%26target_id=kwd-25771213359%26network=o%26match_type=b%26bid_match_type=bb%26msclkid=9665f0c1b8f51fdc3bbaa97e32a358c3%26search_query=spa%20%C3%83%C2%B6stersund%20fr%C3%83%C2%B6s%C3%83%C2%')", expect: '{"errored": "bad utf8 char detected in string"}' , example: false}
                       ]
      },
      {
        type:               :function,
        name:               :bing_click_batch_id_from_url,
        description:        'Returns a unique identifier for a batch of clicks reported by Bing from provided url.',
        params:             "url varchar(max)",
        return_type:        "varchar(max)",
        body:               %~
            import hashlib
            import json
            from urlparse import urlparse, parse_qsl

            def get_value(container, *keys):
                for key in keys:
                    if key in container:
                        return container.get(key)
                return ''

            def get_query_items(url):
                query = urlparse(url).query
                return dict(parse_qsl(query))

            def get_label_items(query_items):
                label = get_value(query_items, 'label', 'Label')
                return dict(parse_qsl(label))

            def get_network(items):
                nk = get_value(items, "nk", "network")
                return "Syndicated" if nk == "s" else "Owned"

            def get_device(items):
                dv = get_value(items, "dv", "device")
                return {
                    "c": "Computer",
                    "m": "Smartphone",
                    "t": "Tablet"}.get(dv, '')

            def get_keyword_id(items):
                tid = get_value(items, "tid", "target_id")
                if tid and tid.startswith("kwd-"):
                    kwd = tid.split(":")[0].strip("kwd-")
                    return kwd
                return ''

            def get_bid_match_type(items):
                bmt = get_value(items, "bmt", "bid_match_type")
                return {
                    "be": "Exact",
                    "bb": "Broad",
                    "bp": "Phrase"}.get(bmt, '')
            try:
                # items come either from query itself of from label within it
                items = get_query_items(url)
                label_items = get_label_items(items)
                items.update(label_items)

                key = {
                    "adgid": get_value(items, "adgid", "ad_group_id"),
                    "adid": get_value(items, "adid", "ad_id"),
                    "kwid": get_keyword_id(items),
                    "dv": get_device(items),
                    "nk": get_network(items),
                    "bmt": get_bid_match_type(items)}

                m = hashlib.md5()
                m.update(json.dumps(key, sort_keys=True).encode())
                return m.hexdigest()
            except UnicodeDecodeError:
                return ''
        ~,
        tests:              [
          {
            query: "select ?('https://it.etrip.net/Hotel/Andaz_Wall_Street.htm?label=clicktype%3DA%26se=bing%26ad_group_id=1622990580%26ad_id=3921223485%26device=m%26target_id=kwd-24794225822:loc-93%26network=o%26match_type=b%26bid_match_type=bb%26msclkid=6ca2cc3d06631184d208964a999f96f4%26search_query=andaz%20hotel%20new%20york&utm_source=bing&utm_medium=cpc&utm_campaign=Lux%20Chains%20-IT-%20LXB&utm_term=Hotel%20Andaz%20New%20York&utm_content=New%20York%20City%20-US-%20Andaz%20-4S-')",
            expect: '75ed585a33ff0eb9083db8d17cb319f6',
            example: true
          },
          {
            query: "select ?('https://www.etrip.net/Hotel.htm?Label=clicktype%3DA%26se=bing%26ad_group_id=1345802350333982%26ad_id=84112665283409%26device=m%26target_id=kwd-84112729113201:loc-96%26network=o%26match_type=e%26bid_match_type=be%26msclkid=2ce23148454515aabd0c6b3fe22d0ce2%26search_query=trivago%26ntv=&utm_source=bing&utm_medium=cpc&utm_campaign=53%20-%20global%20-%20Geo%20-%20Mixed%20-%20Y%20-en-%20Competitors%20general%20Rest%20Languages%20-%20000000&utm_term=trivago&utm_content=Trivago%20General%20-%20E%20-%20EN')",
            expect: '4ff7dab278fdf411b6e56febd8bb9295',
            example: true
          },
          {
            query: "select ?('https://us.etrip.net/Hotels/Search?utm_campaign=54%20-%20global%20-%20Geo%20-%20Mixed%20-%20Y%20-en-%20Competitors%20general%20USA%20-%20000000&highRate=&pageIndex=0&session_id=fh_-N9eBIvy1av2faB86wM6Lw&parentPlaceFilename=&eventSlug=&section=&checkout=2018-03-18&utm_medium=cpc&utm_content=Trivago%20General%20-%20E%20-%20EN&newSearch=false&target_id=kwd-83288081732851:loc-4104&utm_source=bing&checkin=2018-03-15&isAvailabilitySearch=true&destination=Key%20West%2C%20Florida%2C%20United%20States&placeFilename=place:Key_West&lang=en&network=o&reset=false&hotelID=&sortOrder=Ascending&pageSize=25&ntv=&search_query=hotel%20trivago&radius=0&curr=USD&se=bing&search_id=fh_-N9eBIvy1av2faB86wM6Lw%7C15179302878595355&_force_=true&match_type=e&lowRate=&Label=clicktype=A&se=bing&ad_group_id=1332608179538242&ad_id=83288027519017&device=c&target_id=kwd-83288081732851:loc-4104&network=o&match_type=e&bid_match_type=be&msclkid=3f9299015a9a15b79d0dc3789d83b675&search_query=hotel%20trivago&ntv=&isSelectedDateInAnotherMonth=false&validate=false&bid_match_type=be&device=c&shouldStartSearch=true&ad_id=83288027519017&ad_group_id=1332608179538242&msclkid=3f9299015a9a15b79d0dc3789d83b675&rooms=2&hideSearchboxSubmit=false&showCalendar=&hotelFilename=&sortField=MinRate&utm_term=hotel%20trivago&noRedirect=false&searchboxId=homeSearchBox&hotelName=')",
            expect: 'b2401dbbe792106b30bd34820cf783e9',
            example: true
          }
        ]
      },
      {
          type:        :function,
          name:        :make_gha_click_batch_id,
          description: "Returns a unique identifier for a batch of clicks reported by Google Hotel Ads.",
          params:      "date_type varchar(max), google_site varchar(max), country varchar(max), device varchar(max), hotel_id varchar(max), checkin varchar(max), los varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            import hashlib
            import json

            key = {
                "date_type": date_type,
                "google_site": google_site,
                "country": country,
                "device": device,
                "hotel_id": hotel_id,
                "checkin": checkin,
                "los": los}

            m = hashlib.md5()
            m.update(json.dumps(key, sort_keys=True).encode())
            return m.hexdigest()

          ~,
          tests:       [
                           {query: "select ?('default', 'mapresults', 'GB', 'desktop', '1199802', '2018-03-04', '1')", expect: 'c5937b8422c8b1a5f7d3bed0d4abcdb9' , example: true},
                           {query: "select ?('default', 'localuniversal', 'BR', 'mobile', '1', '2018-01-01', '1')", expect: '33f231fd65b8e99ccc2c8e380c4363fb' , example: true},
                           {query: "select ?('default', 'localuniversal', 'BR', 'mobile', '1', '2018-01-01', '1')", expect: '33f231fd65b8e99ccc2c8e380c4363fb' , example: true},
                           {query: "select ?('default', 'localuniversal', 'US', 'mobile', '1', '2018-01-01', '1')", expect: '1e9bff850f22adb5ae7e952b8b02e6ad' , example: true},
                           {query: "select ?('default', 'localuniversal', 'BR', 'tablet', '1', '2018-01-01', '1')", expect: '21dbe3d0af812fe663c1a07ae0e53fd7' , example: true},
                       ]
      },
      {
          type:        :function,
          name:        :gha_click_batch_id_from_url,
          description: "Returns a unique identifier for a batch of clicks reported by Google Hotel Ads.",
          params:      "url varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            import hashlib
            import json
            from urlparse import urlparse, parse_qsl

            def get_query_items(url):
                query = urlparse(url).query
                return dict(parse_qsl(query))

            def get_label_params(items):
                label = items.get('label', items.get('Label', ''))
                return dict(parse_qsl(label))

            params = get_label_params(get_query_items(url))

            key = {
                "date_type": params.get('datype'),
                "google_site": params.get('gsite'),
                "country": params.get('ucountry'),
                "device": params.get('udevice'),
                "hotel_id": params.get('hotel'),
                "checkin": "%s-%s-%s" % (params.get('year', ''), params.get('month', ''), params.get('day', '')),
                "los": params.get('los')}

            m = hashlib.md5()
            m.update(json.dumps(key, sort_keys=True).encode())
            return m.hexdigest()

          ~,
          tests:       [
                           {query: "select ?('https://www.findhotel.net/Place/Manchester_City_Centre.htm?Label=src%3Dgha%26cltype%3Dhotel%26datype%3Ddefault%26gsite%3Dmapresults%26ucountry%3DGB%26udevice%3Ddesktop%26hotel%3D1199802%26day%3D04%26month%3D03%26year%3D2018%26los%3D1&checkin=2018-03-04&checkout=2018-03-05&hotelID=1199802&persist_hotel_id=true&rooms=2')", expect: 'c5937b8422c8b1a5f7d3bed0d4abcdb9' , example: true},
                           {query: "select ?('https://www.findhotel.net/?utm_medium=cpc&Label=src%3Dgha%26cltype%3Dhotel%26datype%3Dselected%26gsite%3Dlocaluniversal%26ucountry%3DUS%26udevice%3Dmobile%26hotel%3D1510016%26day%3D16%26month%3D02%26year%3D2018%26los%3D3')", expect: '9568cc3e30eb740343f8d9762343ca8b' , example: true},
                           {query: "select ?('https://www.findhotel.net/?utm_medium=cpc&label=src%3Dgha%26cltype%3Dhotel%26datype%3Dselected%26gsite%3Dlocaluniversal%26ucountry%3DUS%26udevice%3Dmobile%26hotel%3D1510016%26day%3D16%26month%3D02%26year%3D2018%26los%3D3')", expect: '9568cc3e30eb740343f8d9762343ca8b' , example: true},
                           {query: "select ?('https://www.findhotel.net/?utm_medium=cpc&label=src%3Dgha%26cltype%3Dhotel%26datype%3Dselected%26gsite%3Dlocaluniversal%26ucountry%3DUS%26udevice%3Dmobile%26hotel%3D1510016%26day%3D16%26month%3D02%26year%3D2017%26los%3D3')", expect: '187636d40672026ec80c7b23bd2eb4c5' , example: true},
                           {query: "select ?('https://www.findhotel.net/?utm_medium=cpc&label=src%3Dgha%26cltype%3Dhotel%26datype%3Dselected%26gsite%3Dlocaluniversal%26ucountry%3DUS%26udevice%3Dmobile%26hotel%3D1510016%26day%3D16%26month%3D02%26year%3D2017')", expect: 'a271aace088cd85d22dd71702dacb037' , example: true},
                           {query: "select ?('https://www.findhotel.net/?utm_medium=cpc')", expect: 'd3f701308cedc0a7684b2b3039d4f0bc' , example: true},
                       ]
      }
    ]
end
