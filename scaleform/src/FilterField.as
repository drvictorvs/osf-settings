package
{
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.FocusEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.ui.Keyboard;

    // A boxed text field that narrows a list as the player types: a magnifier, the typed text or
    // a muted hint, and a clear button once there is text. While it has focus the game's text
    // input is on; Enter, Escape, Up or Down hand focus back through leave(direction).
    public final class FilterField extends Sprite
    {
        public var input:TextField;
        private var hint:TextField;
        private var clearButton:Sprite;
        private var boxWidth:Number;
        private var boxHeight:Number;
        private var bridge:Object;
        private var changed:Function;
        private var leave:Function;
        private var lit:Boolean;
        private var focused:Boolean;

        // onChange(): the text changed. onLeave(direction): -1 Up, 1 Down, 0 Enter or Escape.
        public function FilterField(code:Object, id:String, width:Number, height:Number, size:Number, onChange:Function, onLeave:Function)
        {
            name = id; bridge = code; changed = onChange; leave = onLeave;
            boxWidth = width; boxHeight = height;
            var line:Number = size + 12, top:Number = (height - line) / 2 + 2, textLeft:Number = height - 4;
            hint = MenuStyle.field("", textLeft, top, width - textLeft - height, line, size, MenuStyle.MUTED, true);
            input = MenuStyle.field("", textLeft, top, width - textLeft - height, line, size, MenuStyle.WHITE, true);
            input.name = id + "Input"; input.type = "input"; input.selectable = true; input.mouseEnabled = true;
            input.maxChars = 64;
            addChild(hint); addChild(input);
            clearButton = new Sprite(); clearButton.name = id + "Clear"; clearButton.buttonMode = true;
            clearButton.x = width - height;
            var g:Graphics = clearButton.graphics, inset:Number = Math.round(height * 0.34);
            // The game's player skips fully transparent hit areas.
            g.beginFill(MenuStyle.INK, 0.01); g.drawRect(0, 0, height, height); g.endFill();
            g.lineStyle(2, MenuStyle.MUTED);
            g.moveTo(inset, inset); g.lineTo(height - inset, height - inset);
            g.moveTo(height - inset, inset); g.lineTo(inset, height - inset);
            clearButton.addEventListener(MouseEvent.CLICK, clearClicked);
            addChild(clearButton);
            input.addEventListener(Event.CHANGE, textChanged);
            input.addEventListener(FocusEvent.FOCUS_IN, focusChanged);
            input.addEventListener(FocusEvent.FOCUS_OUT, focusChanged);
            update();
        }

        public function get typing():Boolean { return visible && stage && stage.focus == input; }
        public function get text():String { return input.text; }
        // The muted text shown while the field is empty and idle.
        public function set placeholder(value:String):void { MenuStyle.fit(hint, value); }
        // Drawn brighter when keyboard or controller focus is on the field without typing.
        public function set highlighted(value:Boolean):void { if (lit != value) { lit = value; draw(); } }

        public function begin():void
        {
            if (!stage) return;
            stage.focus = input;
            input.setSelection(input.length, input.length);
        }
        public function clear():void
        {
            if (!input.text) return;
            input.text = ""; update(); changed();
        }
        // Empties the field without reporting it, for a list that is being replaced anyway.
        public function reset():void { input.text = ""; update(); }

        // Raw keys while typing. Text keys keep their default handling.
        public function key(event:KeyboardEvent):Boolean
        {
            if (!typing) return false;
            var code:uint = event.keyCode;
            if (code == Keyboard.ENTER || code == Keyboard.ESCAPE) {
                event.preventDefault();
                // Finish on release, like vanilla text entry.
                if (event.type == KeyboardEvent.KEY_UP) leave(0);
            } else if (code == Keyboard.UP || code == Keyboard.DOWN) {
                event.preventDefault();
                if (event.type == KeyboardEvent.KEY_DOWN) leave(code == Keyboard.DOWN ? 1 : -1);
            }
            return true;
        }

        // Every word of the query appears in one of the texts, ignoring case.
        public static function matches(query:String, texts:Array):Boolean
        {
            var words:Array = query.toLowerCase().split(" ");
            var haystack:String = texts.join("\n").toLowerCase();
            for each (var word:String in words) if (word && haystack.indexOf(word) < 0) return false;
            return true;
        }

        private function textChanged(event:Event):void { update(); changed(); }
        private function clearClicked(event:MouseEvent):void { event.stopPropagation(); clear(); }
        private function focusChanged(event:FocusEvent):void
        {
            focused = event.type == FocusEvent.FOCUS_IN;
            bridge.textInput(focused);
            update();
        }
        private function update():void
        {
            hint.visible = !input.text && !focused;
            clearButton.visible = Boolean(input.text);
            draw();
        }
        private function draw():void
        {
            var g:Graphics = graphics, active:Boolean = focused || lit;
            g.clear();
            g.lineStyle(active ? 2 : 1, active ? MenuStyle.WHITE : MenuStyle.LINE);
            g.beginFill(MenuStyle.INK, 0.6); g.drawRect(0, 0, boxWidth, boxHeight); g.endFill();
            // A magnifier: a ring with a short handle.
            var radius:Number = Math.round(boxHeight * 0.17), cx:Number = Math.round(boxHeight * 0.44), cy:Number = Math.round(boxHeight * 0.44);
            g.lineStyle(2, input.text ? MenuStyle.ACCENT : MenuStyle.MUTED);
            g.drawCircle(cx, cy, radius);
            g.moveTo(cx + radius * 0.75, cy + radius * 0.75); g.lineTo(cx + radius * 1.8, cy + radius * 1.8);
            g.lineStyle();
        }
    }
}
