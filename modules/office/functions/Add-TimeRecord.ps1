param(
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Please provide a subject.",
        ValueFromRemainingArguments)]
    [Alias('sub')]
    [string] $Subject,

    # not current, but next slot
    [switch] $Next,

    # not current, but last slot
    [switch] $Last,

    [string] $Category = 'tt',
    [string] $Body = "Started at $($now.ToString('yyyy-MM-ddTHH:mm'))"
)

# https://everything-powershell.com/powershell-7-0-3-create-an-email-message/
# https://social.technet.microsoft.com/Forums/en-US/aa9ef119-b309-48bd-84fe-4847d0117c26/powershell-script-to-create-new-outlook-meeting?forum=winserverpowershell
# https://learn.microsoft.com/en-us/office/vba/api/outlook.appointmentitem.categories

# function Add-CalendarMeeting {
#     param (
#         [cmdletBinding()]
#         # Subject Parameter	
#         [Parameter(
#             Mandatory = $True,
#             HelpMessage = "Please provide a subject of your calendar invite.")]
#         [Alias('sub')]
#         [string] $Subject,

#         #Body parameter
#         [Parameter(
#             Mandatory = $True,
#             HelpMessage = "Please provide a description of your calendar invite.")]
#         [Alias('bod')]
#         [string] $Body,
	
#         # Send Meeting Invites to Required Attendees
#         [Parameter(
#             Mandatory = $True,
#             HelpMessage = "Please provide email address of desired attendee.")]
#         [Alias('invitee')]
#         [string] $ReqAttendee,

#         #Location Parameter
#         [string] $Location = "Virtual",

#         # Importance Parameter
#         [int] $Importance = 1,

#         # Set Reminder Parameter
#         [bool] $EnableReminder = $True,

#         # Metting Start Time Parameter
#         [datetime] $MeetingStart = (Get-Date),

#         # Meeting time duration parameter
#         [int] $MeetingDuration = 120, 

#         # by Default Reminder Duration
#         [int] $Reminder = 15
#     )



begin {
    enum OlItemType {
        # IPM.Note = 0
        olNoteItem = 0
        # IPM.Appointment = 1
        olAppointmentItem = 1
        # IPM.Contact = 2
        olContactItem = 2
        # IPM.Task = 3
        olTaskItem = 3
        # IPM.Activity = 4
        olActivityItem = 4
        # IPM.StickyNote = 5
        olStickyNoteItem = 5
        # IPM.Post = 6
        olPostItem = 6
        # IPM.DistList = 7
        olDistListItem = 7
    }
    
    $now = (Get-Date)

    $start = $now

    if ($Next) {
        $start = $start.AddMinutes(15)
    }

    if ($Last) {
        $start = $start.AddMinutes(-15)
    }

    $minute = switch ($start.Minute) {
        { $_ -ge 44 } {
            45
            break 
        }
        { $_ -ge 29 } {
            30
            break 
        }
        { $_ -ge 14 } {
            15
            break 
        }
        default {
            0 
        }
    }

    $start = Get-Date -Date $start.Date -Hour $start.Hour -Minute $minute -Second 0

    $outlookApplication = New-Object -ComObject 'Outlook.Application'
    $newCalenderItem = $outlookApplication.CreateItem([int][OlItemType]::olAppointmentItem)
}

process {   
    $newCalenderItem.Subject = $Subject
    $newCalenderItem.Body = $Body
    $newCalenderItem.ReminderSet = $false
    $newCalenderItem.ReminderMinutesBeforeStart = 0
    $newCalenderItem.Start = $start
    $newCalenderItem.Duration = 15
    $newCalenderItem.Categories = "tt"

    # $newCalenderItem.Body = $Body
    # $newCalenderItem.Location = $Location
    # $newCalenderItem.ReminderSet = $EnableReminder
    # $newCalenderItem.Importance = $importance
    # $newCalenderItem.RequiredAttendees.Add($ReqAttendee)
    # $newCalenderItem.RequiredAttendees = $ReqAttendee
    # $newCalenderItem.ReminderMinutesBeforeStart = $Reminder
    # $newCalenderItem.Start = $MeetingStart
    # $newCalenderItem.Duration = $MeetingDuration
}

end {   
    Write-Verbose "Saving Calender Item"
    $newCalenderItem.Save()
}
      