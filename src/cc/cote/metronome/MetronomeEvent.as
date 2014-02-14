package cc.cote.metronome
{
	import flash.events.Event;
	
	/**
	 * <code>MetronomeEvent</code> objects are dispatched by a <code>Metronome</code> object to 
	 * inform listeners of changes in the <code>MetronomeEvent</code>'s state.
	 * 
	 * @see cc.cote.metronome.Metronome
	 */
	public class MetronomeEvent extends Event
	{
		
		/** Defines the value of the type property of a tick event object. */
		public static const TICK:String = 'tick';
		
		/** Defines the value of the type property of a stop event object. */
		public static const STOP:String = 'stop';
		
		private var _time:Number;
		private var _count:Number;
		
		/** 
		 * Creates a MetronomeEvent object holding information about the event such as when it 
		 * occured.
		 * 
		 * @param type 	The type of the event.
		 * @param time 	The time at which the event occured (in milliseconds since January 1st, 1970 
		 * 				UTC.
		 * @param count	The number ot ticks triggered by a the Metronome object dispatching this 
		 * 				event since it was started.
		 */
		public function MetronomeEvent(type:String, time:Number, count:Number) {
			super(type);
			_time = time;
			_count = count;
		}
		
		/** 
		 * The time at which the event occured expressed as the number of milliseconds elapsed 
		 * since midnight on January 1st, 1970, universal time.
		 */
		public function get time():Number {
			return _time;
		}
		
		/** The number ot ticks triggered since the Metronome was started. */
		public function get count():Number {
			return _count;
		}
		
	}
	
}
