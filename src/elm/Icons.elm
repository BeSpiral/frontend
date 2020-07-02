module Icons exposing (alert, arrowDown, back, close, communities, dashboard, exclamation, flag, heart, languages, notification, profile, remove, search, settings, shop, success, thumbDown, thumbUp, trash)

import Html exposing (Html)
import Svg exposing (Svg, svg)
import Svg.Attributes exposing (class, clipRule, cx, cy, d, fill, fillRule, height, r, viewBox, width)


dashboard : String -> Svg msg
dashboard class_ =
    svg [ class class_, width "26", height "26", viewBox "0 0 26 26", fill "none" ] [ Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M6.5 1.625H3.25C2.35254 1.625 1.625 2.35254 1.625 3.25V6.5C1.625 7.39746 2.35254 8.125 3.25 8.125H6.5C7.39746 8.125 8.125 7.39746 8.125 6.5V3.25C8.125 2.35254 7.39746 1.625 6.5 1.625ZM6.5 6.5H3.25V3.25H6.5V6.5Z" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M14.625 1.625H11.375C10.4775 1.625 9.75 2.35254 9.75 3.25V6.5C9.75 7.39746 10.4775 8.125 11.375 8.125H14.625C15.5225 8.125 16.25 7.39746 16.25 6.5V3.25C16.25 2.35254 15.5225 1.625 14.625 1.625ZM14.625 6.5H11.375V3.25H14.625V6.5Z" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M22.75 1.625H19.5C18.6025 1.625 17.875 2.35254 17.875 3.25V6.5C17.875 7.39746 18.6025 8.125 19.5 8.125H22.75C23.6475 8.125 24.375 7.39746 24.375 6.5V3.25C24.375 2.35254 23.6475 1.625 22.75 1.625ZM22.75 6.5H19.5V3.25H22.75V6.5Z" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M6.5 9.75H3.25C2.35254 9.75 1.625 10.4775 1.625 11.375V14.625C1.625 15.5225 2.35254 16.25 3.25 16.25H6.5C7.39746 16.25 8.125 15.5225 8.125 14.625V11.375C8.125 10.4775 7.39746 9.75 6.5 9.75ZM6.5 14.625H3.25V11.375H6.5V14.625Z" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M14.625 9.75H11.375C10.4775 9.75 9.75 10.4775 9.75 11.375V14.625C9.75 15.5225 10.4775 16.25 11.375 16.25H14.625C15.5225 16.25 16.25 15.5225 16.25 14.625V11.375C16.25 10.4775 15.5225 9.75 14.625 9.75ZM14.625 14.625H11.375V11.375H14.625V14.625Z" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M22.75 9.75H19.5C18.6025 9.75 17.875 10.4775 17.875 11.375V14.625C17.875 15.5225 18.6025 16.25 19.5 16.25H22.75C23.6475 16.25 24.375 15.5225 24.375 14.625V11.375C24.375 10.4775 23.6475 9.75 22.75 9.75ZM22.75 14.625H19.5V11.375H22.75V14.625Z" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M6.5 17.875H3.25C2.35254 17.875 1.625 18.6025 1.625 19.5V22.75C1.625 23.6475 2.35254 24.375 3.25 24.375H6.5C7.39746 24.375 8.125 23.6475 8.125 22.75V19.5C8.125 18.6025 7.39746 17.875 6.5 17.875ZM6.5 22.75H3.25V19.5H6.5V22.75Z" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M22.75 17.875H19.5C18.6025 17.875 17.875 18.6025 17.875 19.5V22.75C17.875 23.6475 18.6025 24.375 19.5 24.375H22.75C23.6475 24.375 24.375 23.6475 24.375 22.75V19.5C24.375 18.6025 23.6475 17.875 22.75 17.875ZM22.75 22.75H19.5V19.5H22.75V22.75Z" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M14.625 17.875H11.375C10.4775 17.875 9.75 18.6025 9.75 19.5V22.75C9.75 23.6475 10.4775 24.375 11.375 24.375H14.625C15.5225 24.375 16.25 23.6475 16.25 22.75V19.5C16.25 18.6025 15.5225 17.875 14.625 17.875ZM14.625 22.75H11.375V19.5H14.625V22.75Z" ] [] ]


communities : String -> Svg msg
communities class_ =
    svg [ class class_, viewBox "0 0 26 26", fill "none" ] [ Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M23.8261 11.0498L14.0097 2.80426C13.4272 2.31525 12.5728 2.31525 11.9903 2.80426L2.17386 11.0498C1.68639 11.4611 1.50195 12.1253 1.70859 12.7255C1.91524 13.3257 2.47107 13.7401 3.11074 13.7709V22.0165C3.11074 22.8703 3.80983 23.5625 4.6722 23.5625H21.3278C22.1902 23.5625 22.8893 22.8703 22.8893 22.0165V13.776C23.5289 13.7453 24.0848 13.3309 24.2914 12.7307C24.4981 12.1305 24.3136 11.4662 23.8261 11.055V11.0498ZM12.4795 22.0216H11.4385V17.3835H14.5615V22.0216H12.4795ZM21.3278 12.23V22.0216H16.1229V17.3835C16.1229 16.5296 15.4238 15.8374 14.5615 15.8374H11.4385C10.5762 15.8374 9.87707 16.5296 9.87707 17.3835V22.0216H4.67219V12.23H3.1836L13 3.98441L22.8164 12.23H21.3278Z" ] [] ]


shop : String -> Svg msg
shop class_ =
    svg [ class class_, width "26", height "26", viewBox "0 0 26 26", fill "none" ] [ Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M24.1537 1.85143C23.8514 1.54952 23.3617 1.54952 23.0594 1.85143L21.6813 3.22956C21.5519 3.19346 21.4183 3.17438 21.2839 3.17278H13.4538C13.0433 3.17314 12.6497 3.33652 12.3596 3.62699L2.07785 13.9036C1.47405 14.5082 1.47405 15.4875 2.07785 16.0921L9.90788 23.9221C10.5124 24.5259 11.4918 24.5259 12.0964 23.9221L22.373 13.6455C22.6615 13.3546 22.823 12.9611 22.822 12.5513V4.72124C22.8204 4.58686 22.8013 4.45326 22.7652 4.3238L24.1434 2.94567C24.4481 2.64625 24.4528 2.15654 24.1537 1.85143ZM21.2787 12.5513L11.0021 22.8279L3.1721 14.9979L13.4539 4.72124H20.1896L17.8257 7.08522C17.4617 6.89131 17.0561 6.78858 16.6437 6.78585C15.2184 6.78585 14.0629 7.9413 14.0629 9.36662C14.0629 10.7919 15.2184 11.9474 16.6437 11.9474C18.069 11.9474 19.2244 10.7919 19.2244 9.36662C19.2201 8.95378 19.1156 8.54816 18.9199 8.18463L21.2839 5.82064L21.2787 12.5513ZM17.6657 9.36662C17.6657 9.93675 17.2035 10.3989 16.6333 10.3989C16.0632 10.3989 15.601 9.93675 15.601 9.36662C15.601 8.79649 16.0632 8.33431 16.6333 8.33431C16.908 8.33294 17.1719 8.4411 17.3666 8.63484C17.5613 8.82858 17.6708 9.09194 17.6708 9.36662H17.6657Z" ] [] ]


close : String -> Svg msg
close class_ =
    svg [ class class_, width "24", height "24", viewBox "0 0 24 24" ] [ Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M13.6299 12.0242L22.2329 3.25164C22.603 2.84787 22.5865 2.22339 22.1956 1.83974C21.8046 1.4561 21.18 1.45137 20.7833 1.82906L12.1938 10.5881L3.25206 1.81551C2.99607 1.54661 2.6138 1.43874 2.25501 1.53415C1.89622 1.62956 1.61802 1.91306 1.5294 2.2736C1.44078 2.63414 1.55584 3.01431 1.82951 3.26519L10.7577 12.0242L1.82951 20.7832C1.45184 21.1799 1.45656 21.8046 1.8402 22.1956C2.22383 22.5865 2.8483 22.603 3.25206 22.2329L12.1938 13.4603L20.7833 22.2194C21.18 22.597 21.8046 22.5923 22.1956 22.2087C22.5865 21.825 22.603 21.2005 22.2329 20.7968L13.6299 12.0242Z" ] [] ]


alert : String -> Html msg
alert classes =
    svg
        [ viewBox "0 0 32 32"
        , class classes
        ]
        [ Svg.path
            [ fillRule "evenodd"
            , clipRule "evenodd"
            , d "M16 2C8.26801 2 2 8.26801 2 16C2 23.732 8.26801 30 16 30C23.732 30 30 23.732 30 16C30 8.26801 23.732 2 16 2ZM16 28C9.37258 28 4 22.6274 4 16C4 9.37258 9.37258 4 16 4C22.6274 4 28 9.37258 28 16C28 22.6274 22.6274 28 16 28Z"
            ]
            []
        , Svg.path
            [ fillRule "evenodd"
            , clipRule "evenodd"
            , d "M16.3333 7.66666C15.781 7.66666 15.3333 8.11438 15.3333 8.66666V18C15.3333 18.5523 15.781 19 16.3333 19C16.8856 19 17.3333 18.5523 17.3333 18V8.66666C17.3333 8.11438 16.8856 7.66666 16.3333 7.66666Z"
            ]
            []
        , Svg.path
            [ fillRule "evenodd"
            , clipRule "evenodd"
            , d "M16.3333 22.6667C16.8856 22.6667 17.3333 22.219 17.3333 21.6667C17.3333 21.1144 16.8856 20.6667 16.3333 20.6667C15.781 20.6667 15.3333 21.1144 15.3333 21.6667C15.3333 22.219 15.781 22.6667 16.3333 22.6667Z"
            ]
            []
        ]


success : String -> Html msg
success classes =
    svg
        [ viewBox "0 0 32 32"
        , class classes
        ]
        [ Svg.path
            [ fillRule "evenodd"
            , clipRule "evenodd"
            , d "M13.3238 25C12.7916 24.9995 12.2815 24.7955 11.9054 24.4328L2.5387 15.4087C1.80178 14.6467 1.82353 13.4594 2.58788 12.723C3.35224 11.9866 4.58463 11.9657 5.37547 12.6756L13.3238 20.3332L26.6245 7.519C27.4154 6.80903 28.6478 6.82998 29.4121 7.56638C30.1765 8.30278 30.1982 9.4901 29.4613 10.252L14.7422 24.4328C14.3661 24.7955 13.8559 24.9995 13.3238 25Z"
            ]
            []
        ]


notification : String -> Svg msg
notification class_ =
    svg [ width "32", height "32", viewBox "0 0 32 32", fill "none", class class_ ] [ Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M27.4525 23.6028C27.1921 23.3615 25.0769 21.1955 25.0769 14.3608C25.0272 12.0243 24.1647 9.77815 22.6378 8.0089C21.8183 7.02925 20.8037 6.23102 19.6587 5.66505C19.6639 5.608 19.6639 5.5506 19.6587 5.49355C19.6587 3.56411 18.0946 2 16.1652 2C14.2358 2 12.6716 3.56411 12.6716 5.49355C12.6665 5.5506 12.6665 5.608 12.6716 5.66505C11.5267 6.23102 10.5121 7.02925 9.69261 8.0089C8.16566 9.77815 7.30314 12.0243 7.25347 14.3608C7.25347 21.1828 5.14464 23.3424 4.88421 23.5838C4.16959 24.0113 3.83712 24.8699 4.07752 25.6672C4.33116 26.5024 5.11046 27.0661 5.98309 27.0456H12.1953C11.8452 27.4115 11.8452 27.9881 12.1953 28.3541C13.22 29.4064 14.6265 30 16.0953 30C17.5642 30 18.9707 29.4064 19.9954 28.3541C20.3218 27.9935 20.3218 27.4442 19.9954 27.0837H26.2901C27.1628 27.1042 27.9421 26.5405 28.1957 25.7053C28.4555 24.917 28.15 24.0528 27.4525 23.6028ZM16.0576 3.88017C16.7226 3.93687 17.2982 4.36491 17.544 4.9854C16.5636 4.78128 15.5517 4.78128 14.5713 4.9854C14.817 4.36491 15.3927 3.93687 16.0576 3.88017ZM16.1315 6.73852C20.1586 6.73852 23.1186 10.8037 23.1186 14.3608C23.0829 16.5017 23.3328 18.6379 23.8618 20.7127H8.40127C8.93022 18.6379 9.18015 16.5017 9.14444 14.3608C9.14444 10.8037 12.1044 6.73852 16.1315 6.73852ZM16.0262 28.1063C15.0721 28.1166 14.1548 27.7382 13.4854 27.0583H18.5034C17.8498 27.7231 16.9584 28.1002 16.0262 28.1063ZM5.99728 25.159C6.7918 24.4755 7.39945 23.6012 7.76311 22.6183H24.5639C24.9276 23.6012 25.5352 24.4755 26.3297 25.159H5.99728Z" ] [] ]


search : String -> Svg msg
search class_ =
    svg [ width "28", height "28", viewBox "0 0 28 28", fill "none", class class_ ] [ Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M25.9969 24.7134L20.1885 19.2244C24.2584 15.3336 24.3824 9.08776 20.4699 5.05379C16.5574 1.01982 9.99564 0.628044 5.58244 4.16492C1.16924 7.70179 0.469389 13.9132 3.9946 18.2576C7.51981 22.6019 14.0201 23.5388 18.7427 20.3832L24.6643 26.0095C25.0358 26.3385 25.6147 26.3288 25.9738 25.9876C26.3329 25.6464 26.3431 25.0963 25.9969 24.7433V24.7134ZM3.80046 12.0571C3.80046 7.43892 7.74064 3.69516 12.6011 3.69516C17.4616 3.69516 21.4018 7.43892 21.4018 12.0571C21.4018 16.6752 17.4616 20.419 12.6011 20.419C7.74064 20.419 3.80046 16.6752 3.80046 12.0571Z" ] [] ]


arrowDown : String -> Svg msg
arrowDown class_ =
    svg [ width "32", height "32", viewBox "0 0 32 32", class class_ ] [ Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M16 30C23.732 30 30 23.732 30 16C30 8.26801 23.732 2 16 2C8.26801 2 2 8.26801 2 16C2 23.732 8.26801 30 16 30Z", fill "white" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M14.9881 19.8182C15.0302 19.8496 15.0749 19.8773 15.1217 19.9009C15.1713 19.9401 15.2246 19.9742 15.2808 20.0028C15.3388 20.0213 15.3985 20.0341 15.459 20.0409C15.5747 20.0793 15.6997 20.0793 15.8154 20.0409C15.8759 20.0341 15.9356 20.0213 15.9935 20.0028C16.0498 19.9742 16.1031 19.9401 16.1526 19.9009C16.1995 19.8773 16.2442 19.8496 16.2863 19.8182L21.059 14.7273C21.4113 14.3414 21.3878 13.7439 21.0064 13.3869C20.6249 13.0298 20.0272 13.0458 19.6654 13.4228L15.5863 17.7691L11.5072 13.4228C11.1454 13.0458 10.5477 13.0298 10.1662 13.3869C9.78469 13.7439 9.76124 14.3414 10.1135 14.7273L14.9881 19.8182Z" ] [] ]


remove : String -> Svg msg
remove class_ =
    svg [ class class_, width "28", height "28", viewBox "0 0 28 28" ] [ Svg.circle [ cx "14", cy "14", r "14", fill "#DB1B1B" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", fill "white", d "M14.8776 14.0131L19.51 9.28938C19.7093 9.07197 19.7004 8.73571 19.4899 8.52913C19.2794 8.32255 18.943 8.32001 18.7294 8.52338L14.1043 13.2398L9.28955 8.51608C9.1517 8.37129 8.94587 8.31321 8.75267 8.36458C8.55948 8.41596 8.40968 8.56861 8.36196 8.76274C8.31424 8.95688 8.3762 9.16159 8.52356 9.29668L13.331 14.0131L8.52356 18.7295C8.3202 18.9431 8.32274 19.2794 8.52931 19.49C8.73589 19.7005 9.07214 19.7094 9.28955 19.5101L14.1043 14.7864L18.7294 19.5028C18.943 19.7061 19.2794 19.7036 19.4899 19.497C19.7004 19.2904 19.7093 18.9542 19.51 18.7368L14.8776 14.0131Z" ] [] ]


thumbUp : String -> Svg msg
thumbUp class_ =
    svg [ class class_, width "32", height "32", viewBox "0 0 32 32" ] [ Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M30 14.5969C30 12.6643 28.4712 11.0977 26.5854 11.0977H21.8049V6.19895C21.8049 4.09948 20.6302 2 18.3902 2C16.1502 2 14.9756 4.09948 14.9756 6.19895V8.13047L12.5102 10.6568L9.35512 11.7066C9.03988 10.9202 8.293 10.4063 7.46341 10.4049H4.04878C2.91727 10.4049 2 11.3449 2 12.5044V27.9005C2 29.06 2.91727 30 4.04878 30H7.46341C8.59492 30 9.5122 29.06 9.5122 27.9005V27.6276L12.4761 29.6501C12.8121 29.8785 13.2065 30.0002 13.6098 30H26.5854C28.4712 30 30 28.4334 30 26.5009V25.801C29.634 25.1515 29.634 24.3512 30 23.7016V21.6021C29.634 20.9525 29.634 20.1522 30 19.5026V17.4031C29.634 16.7536 29.634 15.9533 30 15.3037V14.5969ZM7.46341 27.8935H4.04878V12.4974H7.46341V27.8935ZM27.9512 15.2967H26.9268C26.3611 15.2967 25.9024 15.7667 25.9024 16.3464C25.9024 16.9262 26.3611 17.3961 26.9268 17.3961H27.9512V19.4956H26.9268C26.3611 19.4956 25.9024 19.9656 25.9024 20.5454C25.9024 21.1251 26.3611 21.5951 26.9268 21.5951H27.9512V23.6946H26.9268C26.3611 23.6946 25.9024 24.1646 25.9024 24.7443C25.9024 25.3241 26.3611 25.794 26.9268 25.794H27.9512V26.4939C27.9512 27.2669 27.3397 27.8935 26.5854 27.8935H13.6098L9.5122 25.0942V13.855L13.6098 12.4974L17.0244 8.99825V6.19895C17.0244 6.19895 17.0244 4.09947 18.3902 4.09947C19.7561 4.09947 19.7561 6.19895 19.7561 6.19895V13.1972H26.5854C27.3397 13.1972 27.9512 13.8238 27.9512 14.5968V15.2967Z" ] [] ]


thumbDown : String -> Svg msg
thumbDown class_ =
    svg [ class class_, width "32", height "32", viewBox "0 0 32 32" ] [ Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M2 17.4031C2 19.3357 3.52878 20.9023 5.41463 20.9023L10.1951 20.9023V25.801C10.1951 27.9005 11.3698 30 13.6098 30C15.8498 30 17.0244 27.9005 17.0244 25.801V23.8695L19.4898 21.3432L22.6449 20.2934C22.9601 21.0798 23.707 21.5937 24.5366 21.5951H27.9512C29.0827 21.5951 30 20.6551 30 19.4956L30 4.09948C30 2.93997 29.0827 2 27.9512 2H24.5366C23.4051 2 22.4878 2.93997 22.4878 4.09948V4.37241L19.5239 2.34991C19.1879 2.12149 18.7935 1.99977 18.3902 2L5.41463 2C3.52878 2 2 3.56661 2 5.49913V6.19895C2.36598 6.84853 2.36598 7.64885 2 8.29843V10.3979C2.36598 11.0475 2.36598 11.8478 2 12.4974V14.5969C2.36598 15.2464 2.36598 16.0467 2 16.6963V17.4031ZM24.5366 4.10647H27.9512L27.9512 19.5026H24.5366L24.5366 4.10647ZM4.04878 16.7033H5.07317C5.63893 16.7033 6.09756 16.2333 6.09756 15.6536C6.09756 15.0738 5.63893 14.6039 5.07317 14.6039H4.04878V12.5044H5.07317C5.63893 12.5044 6.09756 12.0344 6.09756 11.4546C6.09756 10.8749 5.63893 10.4049 5.07317 10.4049H4.04878V8.30543H5.07317C5.63893 8.30543 6.09756 7.83544 6.09756 7.25569C6.09756 6.67594 5.63893 6.20595 5.07317 6.20595H4.04878V5.50613C4.04878 4.73312 4.66029 4.10648 5.41463 4.10648L18.3902 4.10648L22.4878 6.90578L22.4878 18.145L18.3902 19.5026L14.9756 23.0018V25.8011C14.9756 25.8011 14.9756 27.9005 13.6098 27.9005C12.2439 27.9005 12.2439 25.8011 12.2439 25.8011V18.8028L5.41463 18.8028C4.66029 18.8028 4.04878 18.1762 4.04878 17.4032V16.7033Z" ] [] ]


back : String -> Svg msg
back class_ =
    svg [ width "28", height "28", viewBox "0 0 28 28", class class_ ] [ Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M0 14C0 21.732 6.26801 28 14 28C21.732 28 28 21.732 28 14C28 6.26801 21.732 0 14 0C6.26801 0 0 6.26801 0 14Z", fill "white" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M10.1818 12.9881C10.1504 13.0302 10.1227 13.0749 10.0991 13.1217C10.0599 13.1713 10.0258 13.2246 9.99724 13.2808C9.97866 13.3388 9.96587 13.3985 9.95906 13.459C9.92071 13.5747 9.92071 13.6997 9.95906 13.8154C9.96587 13.8759 9.97866 13.9356 9.99724 13.9935C10.0258 14.0498 10.0599 14.1031 10.0991 14.1526C10.1227 14.1995 10.1504 14.2442 10.1818 14.2863L15.2727 19.059C15.6586 19.4113 16.2561 19.3878 16.6131 19.0064C16.9702 18.6249 16.9542 18.0272 16.5772 17.6654L12.2309 13.5863L16.5772 9.50718C16.9542 9.14536 16.9702 8.54766 16.6131 8.16617C16.2561 7.78469 15.6586 7.76124 15.2727 8.11354L10.1818 12.9881Z" ] [] ]


heart : Svg msg
heart =
    svg [ width "49", height "32", viewBox "0 0 49 32", fill "none" ] [ Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M24.4692 27.1195C24.4692 27.1195 12.3218 19.4394 12.3218 10.6168C12.3218 7.20833 14.4914 4.9043 17.8298 4.9043C21.1681 4.9043 24.1335 9.34734 24.7552 9.34734C25.3768 9.34734 28.2552 4.9043 31.5935 4.9043C34.9319 4.9043 36.5669 7.20833 36.5669 10.6168C36.5918 19.3569 24.4692 27.1195 24.4692 27.1195Z", fill "#DB1B1B" ] [] ]


profile : String -> Svg msg
profile class_ =
    svg [ width "32", height "32", viewBox "0 0 32 32", class class_ ] [ Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M16 3C8.8203 3 3 8.8203 3 16C3 23.1797 8.8203 29 16 29C23.1797 29 29 23.1797 29 16C29 8.8203 23.1797 3 16 3ZM4.77273 16C4.77237 11.0828 7.9718 6.7375 12.6674 5.27792C17.363 3.81834 22.462 5.58413 25.2493 9.63505C28.0366 13.686 27.8635 19.0793 24.8223 22.9432C23.4677 20.9257 21.5024 19.3953 19.2145 18.5764C20.2033 17.518 20.7452 16.1187 20.7273 14.6705C20.7273 11.7159 18.6059 9.35227 16 9.35227C13.3941 9.35227 11.2727 11.7159 11.2727 14.6705C11.258 16.1704 11.8455 17.6136 12.9036 18.6768C10.5995 19.5039 8.65606 21.1088 7.40818 23.215C5.70471 21.197 4.77102 18.6409 4.77273 16ZM16.2955 18.0682C15.9717 18.0695 15.6483 18.0873 15.3264 18.1214C13.8883 17.5999 12.9616 16.1979 13.0455 14.6705C13.0455 12.7145 14.3691 11.125 16 11.125C17.6309 11.125 18.9545 12.7145 18.9545 14.6705C19.0274 16.1549 18.1558 17.5238 16.78 18.0859C16.6205 18.08 16.4609 18.0682 16.2955 18.0682ZM8.72 24.5682C10.0043 22.0608 12.4298 20.3365 15.22 19.9473C15.7952 20.0596 16.388 20.0455 16.9573 19.9059C19.7148 20.2783 22.1494 21.8941 23.5636 24.2905C19.3964 28.1368 13.0103 28.2562 8.70227 24.5682H8.72Z", fill "#999999" ] [] ]


languages : String -> Svg msg
languages class_ =
    svg [ width "32", height "32", viewBox "0 0 32 32", class class_ ] [ Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M24.2727 4.09979C26.3815 4.09979 28.0909 5.98001 28.0909 8.29937V19.4983C28.0909 21.8176 26.3815 23.6978 24.2727 23.6978H12.6591L8.36364 27.8974V23.6978H7.72728C5.61855 23.6978 3.90909 21.8176 3.90909 19.4983V8.29937C3.90909 5.98001 5.61855 4.09979 7.72728 4.09979H24.2727ZM24.2727 2H7.72727C4.56419 2 2 4.82032 2 8.29937V19.4983C1.9985 22.4393 3.84747 24.9901 6.45455 25.6436V27.8974C6.45356 28.726 6.89564 29.4777 7.58311 29.8165C8.27058 30.1552 9.07488 30.0176 9.63636 29.4653L13.3909 25.7976H24.2727C27.4358 25.7976 30 22.9773 30 19.4983V8.29937C30 4.82032 27.4358 2 24.2727 2V2Z", fill "#999999" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M16 14.9487C16.5271 14.9487 16.9545 14.4786 16.9545 13.8988C16.9545 13.3189 16.5271 12.8489 16 12.8489C15.4728 12.8489 15.0454 13.3189 15.0454 13.8988C15.0454 14.4786 15.4728 14.9487 16 14.9487Z", fill "#999999" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M22.3636 14.9487C22.8908 14.9487 23.3181 14.4786 23.3181 13.8988C23.3181 13.3189 22.8908 12.8489 22.3636 12.8489C21.8364 12.8489 21.4091 13.3189 21.4091 13.8988C21.4091 14.4786 21.8364 14.9487 22.3636 14.9487Z", fill "#999999" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M9.71272 14.9487C10.2399 14.9487 10.6673 14.4786 10.6673 13.8988C10.6673 13.3189 10.2399 12.8489 9.71272 12.8489C9.18554 12.8489 8.75818 13.3189 8.75818 13.8988C8.75818 14.4786 9.18554 14.9487 9.71272 14.9487Z", fill "#999999" ] [] ]


flag : String -> Svg msg
flag class_ =
    svg [ width "40", height "46", viewBox "0 0 40 46", class class_ ] [ Svg.path [ d "M0.439542 11.1667L19.5604 0.110077C19.829 -0.0366924 20.1709 -0.0366924 20.4395 0.110077L39.5604 11.1667C39.829 11.3135 40 11.607 40 11.925V34.0628C40 34.3808 39.829 34.6743 39.5604 34.8211L20.4395 45.8777C20.293 45.9511 20.1465 46 20 46C19.8535 46 19.7069 45.9511 19.5604 45.8777L0.439542 34.8211C0.170922 34.6743 0 34.3808 0 34.0628V11.925C0 11.607 0.170922 11.3135 0.439542 11.1667Z", fill "#8ACC9E" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M27.0759 19.7659L29.3273 16.2036C29.6024 15.7688 29.599 15.2358 29.3182 14.8039C29.0375 14.372 28.5217 14.1064 27.9639 14.1065H13.2858C13.2858 13.7187 12.935 13.4043 12.5023 13.4043C12.0695 13.4043 11.7188 13.7187 11.7188 14.1065V31.8947C11.7188 32.2825 12.0695 32.5969 12.5023 32.5969C12.935 32.5969 13.2858 32.2825 13.2858 31.8947V25.8092H27.9117C28.4543 25.8086 28.9578 25.5565 29.2429 25.1428C29.528 24.7291 29.554 24.2127 29.3116 23.7776L27.0759 19.7659ZM13.2858 24.4049V15.5108H27.9117L25.2634 19.7238L27.8751 24.4049H13.2858Z", fill "white" ] [] ]


exclamation : String -> Svg msg
exclamation class_ =
    svg [ width "24", height "24", viewBox "0 0 24 24", class class_ ] [ Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M12 1.5C6.20101 1.5 1.5 6.20101 1.5 12C1.5 17.799 6.20101 22.5 12 22.5C17.799 22.5 22.5 17.799 22.5 12C22.5 6.20101 17.799 1.5 12 1.5ZM12 21C7.02944 21 3 16.9706 3 12C3 7.02944 7.02944 3 12 3C16.9706 3 21 7.02944 21 12C21 16.9706 16.9706 21 12 21Z", fill "black" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M12.25 5.75C11.8358 5.75 11.5 6.08579 11.5 6.5V13.5C11.5 13.9142 11.8358 14.25 12.25 14.25C12.6642 14.25 13 13.9142 13 13.5V6.5C13 6.08579 12.6642 5.75 12.25 5.75Z", fill "black" ] [], Svg.path [ fillRule "evenodd", clipRule "evenodd", d "M12.25 17C12.6642 17 13 16.6642 13 16.25C13 15.8358 12.6642 15.5 12.25 15.5C11.8358 15.5 11.5 15.8358 11.5 16.25C11.5 16.6642 11.8358 17 12.25 17Z", fill "black" ] [] ]


trash : String -> Svg msg
trash class_ =
    svg [ width "24", height "24", viewBox "0 0 24 24", class class_ ] [ Svg.path [ fillRule "evenodd", clipRule "evenOdd", d "M20.3077 5.16788H16.3477C15.6644 3.41192 13.9331 2.25 12 2.25C10.0669 2.25 8.33558 3.41192 7.65231 5.16788H3.69231C3.30996 5.16788 3 5.46885 3 5.84013C3 6.2114 3.30996 6.51237 3.69231 6.51237H4.15385V20.4055C4.15385 21.148 4.77376 21.75 5.53846 21.75H18C18.7647 21.75 19.3846 21.148 19.3846 20.4055V6.51237H20.3077C20.69 6.51237 21 6.2114 21 5.84013C21 5.46885 20.69 5.16788 20.3077 5.16788ZM12 3.5993C13.26 3.5993 14.3538 4.04746 14.8938 5.16788H9.10615C9.64615 4.04298 10.74 3.5993 12 3.5993ZM18 20.4055H16.1538V12.7867C16.1538 12.4154 15.8439 12.1144 15.4615 12.1144C15.0792 12.1144 14.7692 12.4154 14.7692 12.7867V20.4055H12.4615V10.0977C12.4615 9.72643 12.1516 9.42545 11.7692 9.42545C11.3869 9.42545 11.0769 9.72643 11.0769 10.0977V20.4055H8.76923V12.7867C8.76923 12.4154 8.45927 12.1144 8.07692 12.1144C7.69457 12.1144 7.38462 12.4154 7.38462 12.7867V20.4055H5.53846V6.51237H18V20.4055Z", fill "#DB1B1B" ] [] ]


settings : Svg msg
settings =
    svg [ fill "none", height "28", viewBox "0 0 28 28", width "28" ]
        [ Svg.path [ clipRule "evenodd", d "M14 8.90906C11.1884 8.90906 8.90909 11.1883 8.90909 14C8.90909 16.8116 11.1884 19.0909 14 19.0909C16.8116 19.0909 19.0909 16.8116 19.0909 14C19.0909 11.1883 16.8116 8.90906 14 8.90906ZM14 17.1818C12.2427 17.1818 10.8182 15.7572 10.8182 14C10.8182 12.2427 12.2427 10.8181 14 10.8181C15.7573 10.8181 17.1818 12.2427 17.1818 14C17.1818 15.7572 15.7573 17.1818 14 17.1818Z", fill "black", fillRule "evenodd" ]
            []
        , Svg.path [ clipRule "evenodd", d "M26.0909 10.1818H25.4545C25.2812 9.63475 25.0685 9.10093 24.8182 8.58455L25.2573 8.14545C26.0017 7.4001 26.0017 6.19263 25.2573 5.44727L22.5591 2.74909C21.8137 2.00466 20.6063 2.00466 19.8609 2.74909L19.4091 3.18182C18.8927 2.93148 18.3589 2.71881 17.8118 2.54545V1.90909C17.8118 0.854729 16.9571 0 15.9027 0H12.0845C11.0302 0 10.1755 0.854729 10.1755 1.90909V2.54545C9.62839 2.71881 9.09457 2.93148 8.57818 3.18182L8.13909 2.74273C7.39373 1.9983 6.18626 1.9983 5.44091 2.74273L2.74273 5.44091C1.9983 6.18626 1.9983 7.39374 2.74273 8.13909L3.18182 8.57818C2.93146 9.09456 2.71878 9.62838 2.54545 10.1755H1.90909C0.854729 10.1755 0 11.0302 0 12.0845V15.9027C0 16.9571 0.854729 17.8118 1.90909 17.8118H2.54545C2.71878 18.3589 2.93146 18.8927 3.18182 19.4091L2.74273 19.8482C1.9983 20.5935 1.9983 21.801 2.74273 22.5464L5.44091 25.2445C6.18626 25.989 7.39373 25.989 8.13909 25.2445L8.59091 24.8182C9.1073 25.0685 9.64111 25.2812 10.1882 25.4545V26.0909C10.1882 27.1453 11.0429 28 12.0973 28H15.9154C16.9698 28 17.8245 27.1453 17.8245 26.0909V25.4545C18.3716 25.2812 18.9054 25.0685 19.4218 24.8182L19.8609 25.2573C20.6063 26.0017 21.8137 26.0017 22.5591 25.2573L25.2573 22.5591C26.0017 21.8137 26.0017 20.6063 25.2573 19.8609L24.8182 19.4218C25.0685 18.9054 25.2812 18.3716 25.4545 17.8245H26.0909C27.1453 17.8245 28 16.9698 28 15.9155V12.0973C28.0017 11.5898 27.8013 11.1026 27.4431 10.7432C27.0849 10.3838 26.5983 10.1818 26.0909 10.1818ZM26.0909 15.9091H23.9973C23.7392 17.2768 23.202 18.5765 22.4191 19.7273L23.8954 21.2036L21.1973 23.9018L19.7209 22.4255C18.5703 23.2085 17.2704 23.7458 15.9027 24.0036V26.0909H12.0845V23.9973C10.7168 23.7394 9.417 23.2022 8.26636 22.4191L6.79 23.8955L4.09181 21.1973L5.56818 19.7209C4.78527 18.5702 4.24803 17.2704 3.99 15.9027H1.90909V12.0845H4.00272C4.26075 10.7169 4.798 9.41709 5.58091 8.26636L4.10454 6.79L6.80272 4.09182L8.27909 5.56818C9.42981 4.78527 10.7296 4.24803 12.0973 3.99V1.90909H15.9154V4.00273C17.2831 4.26076 18.5829 4.798 19.7336 5.58091L21.21 4.10455L23.9082 6.80273L22.4191 8.27273C23.202 9.42345 23.7392 10.7232 23.9973 12.0909H26.0909V15.9091Z", fill "black", fillRule "evenodd" ]
            []
        ]
