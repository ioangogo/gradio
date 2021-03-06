using Gee;

namespace Gradio{

	public class StationProvider{
		// for the search thread
		private bool _isWorking = false;
		public signal void status_changed();
		public bool isWorking { get { return _isWorking;} set { _isWorking = value; status_changed();}}


		// Get the station data from ID
		public RadioStation parse_station_data_from_id (int id){
			Json.Parser parser = new Json.Parser ();
			RadioStation new_station = null;

			string data = Util.get_string_from_uri(RadioBrowser.radio_stations_by_id + id.to_string());
			try{
				if(data != ""){
					parser.load_from_data (data);
					var root = parser.get_root ();
					var radio_stations = root.get_array ();

					if(radio_stations.get_length() != 0){
						var radio_station = radio_stations.get_element(0);
						var radio_station_data = radio_station.get_object ();

						new_station = parse_station_data_from_json(radio_station_data);
					}
				}
			}catch (Error e){
				error("Parser: " + e.message);
			}

			return new_station;
		}


		// Parse the station data and return a station object
		private RadioStation parse_station_data_from_json (Json.Object radio_station_data){
			string title = radio_station_data.get_string_member("name");
			string homepage = radio_station_data.get_string_member("homepage");
			string language = radio_station_data.get_string_member("language");
			string id = radio_station_data.get_string_member("id");
			string icon = radio_station_data.get_string_member("favicon");
			string country = radio_station_data.get_string_member("country");
			string tags = radio_station_data.get_string_member("tags");
			string state = radio_station_data.get_string_member("state");
			string votes = radio_station_data.get_string_member("votes");
			string codec = radio_station_data.get_string_member("codec");
			string bitrate = radio_station_data.get_string_member("bitrate");
			bool broken;

			if(radio_station_data.get_string_member("lastcheckok") == "1")
				broken = false;
			else
				broken = true;

			RadioStation station = new RadioStation(title, homepage, language, id, icon, country, tags, state, votes, codec, bitrate, broken);
			return station;
		}


		// Handle several stations and return them as a map
		public async HashMap<int,RadioStation> get_radio_stations(string address, int max_results) throws ThreadError{
			SourceFunc callback = get_radio_stations.callback;
			HashMap<int,RadioStation> output = new HashMap<int,RadioStation>();

			isWorking = true;
			ThreadFunc<void*> run = () => {
				try{
		   			HashMap<int,RadioStation> results = new HashMap<int,RadioStation>();
					string data = Util.get_string_from_uri(address);
					Json.Parser parser = new Json.Parser ();

					if(data != ""){
						parser.load_from_data (data);
						var root = parser.get_root ();
						var radio_stations = root.get_array ();

						int max_items = (int)radio_stations.get_length();
						if(max_items < max_results)
							max_results = max_items;

						for(int a = 0; a < max_results; a++){
							var radio_station = radio_stations.get_element(a);
							var radio_station_data = radio_station.get_object ();

							var station = parse_station_data_from_json(radio_station_data);

							results[int.parse(station.ID)] = station;
						}

						output = results;
					}else{
						output = null;
					}

				}catch(GLib.Error e){
					warning(e.message);
				}

				Idle.add((owned) callback);
				Thread.exit (1.to_pointer ());
				return null;
			};

			new Thread<void*> ("search_thread", run);

			yield;
			isWorking = false;
           		return output;
        	}

	}

}
