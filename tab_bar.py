from datetime import datetime

from kitty.boss import get_boss
from kitty.fast_data_types import Screen, add_timer, get_options
from kitty.utils import color_as_int
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
    draw_title,
)

opts = get_options()
clock_color = as_rgb(color_as_int(opts.color15))

REFRESH_TIME = 1.0
_timer_started = False


def _redraw_tab_bar(timer_id=None):
    tm = get_boss().active_tab_manager
    if tm is not None:
        tm.mark_tab_bar_dirty()


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    global _timer_started
    if not _timer_started:
        add_timer(_redraw_tab_bar, REFRESH_TIME, True)
        _timer_started = True

    end = draw_title(draw_data, screen, tab, index, max_title_length)

    if is_last:
        now = datetime.now()
        clock_str = now.strftime("%H:%M:%S")
        date_str = now.strftime("%a %d %b").upper()
        text = f"  Francisco Gómez   {date_str}   {clock_str}  "
        text_len = len(text)
        if screen.columns - text_len > screen.cursor.x:
            screen.cursor.x = screen.columns - text_len
            screen.cursor.bg = 0
            screen.cursor.fg = clock_color
            screen.draw(text)

    return end
