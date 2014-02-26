package cc.cote.metronome
{
	import flash.events.Event;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * <code>MetronomeEvent</code> objects are dispatched by a <code>Metronome</code> object to 
	 * inform listeners of changes in the <code>MetronomeEvent</code>'s state.
	 * 
	 * @see cc.cote.metronome.Metronome
	 */
	public class MetronomeEvent extends Event
	{
		
		/** 
		 * The <code>TICK</code> constant defines the value of the <code>type</code> property of a 
		 * <code>tick</code> event object.
		 * 
		 * @eventType tick
		 */
		public static const TICK:String = 'tick';

		/** 
		 * The <code>START</code> constant defines the value of the <code>type</code> property of a 
		 * <code>start</code> event object.
		 * 
		 * @eventType start
		 */
		public static const START:String = 'start';
		
		/** 
		 * The <code>STOP</code> constant defines the value of the <code>STOP</code> property of a 
		 * <code>STOP</code> event object.
		 * 
		 * @eventType start
		 */
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
		 * Returns a string representation of the event including the most useful properties for
		 * debugging.
		 */
		override public function toString():String {

			return 	'[' + getQualifiedClassName(this).split("::").pop() + 
				' type="' + type + '" time=' + _time + 
				' count=' + _count + ']';
		
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
