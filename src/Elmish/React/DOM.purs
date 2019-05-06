module Elmish.React.DOM
    ( empty
    , text
    , fragment
    , module Generated
    ) where

import Elmish.React (ReactComponent, ReactElement, createElement)
import Elmish.React.DOM.Generated (OptProps_a, OptProps_abbr, OptProps_address, OptProps_area, OptProps_article, OptProps_aside, OptProps_audio, OptProps_b, OptProps_base, OptProps_bdi, OptProps_bdo, OptProps_blockquote, OptProps_body, OptProps_br, OptProps_button, OptProps_canvas, OptProps_caption, OptProps_cite, OptProps_code, OptProps_col, OptProps_colgroup, OptProps_data, OptProps_datalist, OptProps_dd, OptProps_del, OptProps_details, OptProps_dfn, OptProps_dialog, OptProps_div, OptProps_dl, OptProps_dt, OptProps_em, OptProps_embed, OptProps_fieldset, OptProps_figcaption, OptProps_figure, OptProps_footer, OptProps_form, OptProps_h1, OptProps_h2, OptProps_h3, OptProps_h4, OptProps_h5, OptProps_h6, OptProps_head, OptProps_header, OptProps_hgroup, OptProps_hr, OptProps_html, OptProps_i, OptProps_iframe, OptProps_img, OptProps_input, OptProps_ins, OptProps_kbd, OptProps_keygen, OptProps_label, OptProps_legend, OptProps_li, OptProps_link, OptProps_main, OptProps_map, OptProps_mark, OptProps_math, OptProps_menu, OptProps_menuitem, OptProps_meta, OptProps_meter, OptProps_nav, OptProps_noscript, OptProps_object, OptProps_ol, OptProps_optgroup, OptProps_option, OptProps_output, OptProps_p, OptProps_param, OptProps_picture, OptProps_pre, OptProps_progress, OptProps_q, OptProps_rb, OptProps_rp, OptProps_rt, OptProps_rtc, OptProps_ruby, OptProps_s, OptProps_samp, OptProps_script, OptProps_section, OptProps_select, OptProps_slot, OptProps_small, OptProps_source, OptProps_span, OptProps_strong, OptProps_style, OptProps_sub, OptProps_summary, OptProps_sup, OptProps_svg, OptProps_table, OptProps_tbody, OptProps_td, OptProps_template, OptProps_textarea, OptProps_tfoot, OptProps_th, OptProps_thead, OptProps_time, OptProps_title, OptProps_tr, OptProps_track, OptProps_u, OptProps_ul, OptProps_var, OptProps_video, OptProps_wbr, a, abbr, address, area, article, aside, audio, b, base, bdi, bdo, blockquote, body, br, button, canvas, caption, cite, code, col, colgroup, data', datalist, dd, del, details, dfn, dialog, div, dl, dt, em, embed, fieldset, figcaption, figure, footer, form, h1, h2, h3, h4, h5, h6, head, header, hgroup, hr, html, i, iframe, img, input, ins, kbd, keygen, label, legend, li, link, main, map, mark, math, menu, menuitem, meta, meter, nav, noscript, object, ol, optgroup, option, output, p, param, picture, pre, progress, q, rb, rp, rt, rtc, ruby, s, samp, script, section, select, slot, small, source, span, strong, style, sub, summary, sup, svg, table, tbody, td, template, textarea, tfoot, th, thead, time, title, tr, track, u, ul, var, video, wbr) as Generated
import Unsafe.Coerce (unsafeCoerce)

-- | Empty React element.
empty :: ReactElement
empty = unsafeCoerce false

-- | Render a plain string as a React element.
text :: String -> ReactElement
text = unsafeCoerce

-- | Wraps multiple React elements as a single one (import of React.Fragment)
fragment :: Array ReactElement -> ReactElement
fragment = createElement fragment_ {}

foreign import fragment_ :: ReactComponent {}
