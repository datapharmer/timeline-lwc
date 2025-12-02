/**
 * @description Component to display Chatter items in the timeline
 * @author Timeline LWC Team
 * @date 2024
 */
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class ChatterTimelineItem extends NavigationMixin(LightningElement) {
    @api timelineItem;
    @api isExpanded = false;
    
    showComments = false;
    showAttachments = false;
    
    get isChatterPost() {
        return this.timelineItem.objectName === 'FeedItem';
    }
    
    get isChatterComment() {
        return this.timelineItem.objectName === 'FeedComment';
    }
    
    get hasComments() {
        return this.timelineItem.commentCount && this.timelineItem.commentCount > 0;
    }
    
    get hasAttachments() {
        return this.timelineItem.hasAttachment === true;
    }
    
    get formattedDate() {
        if (this.timelineItem.dateValue) {
            const date = new Date(this.timelineItem.dateValue);
            return new Intl.DateTimeFormat('en-US', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            }).format(date);
        }
        return '';
    }
    
    get postTypeLabel() {
        const typeLabels = {
            'TextPost': 'Post',
            'LinkPost': 'Link',
            'ContentPost': 'File',
            'TrackedChange': 'Field Update',
            'QuestionPost': 'Question',
            'PollPost': 'Poll',
            'Comment': 'Comment'
        };
        return typeLabels[this.timelineItem.type] || this.timelineItem.type;
    }
    
    get itemClass() {
        let classes = 'slds-timeline__item_expandable ';
        if (this.isExpanded) {
            classes += 'slds-is-open';
        }
        if (this.isChatterComment) {
            classes += ' slds-m-left_x-large';
        }
        return classes;
    }
    
    get bodyContent() {
        // Sanitize and format the body content
        if (this.timelineItem.detailField) {
            // Convert URLs to clickable links
            let content = this.timelineItem.detailField;
            const urlRegex = /(https?:\/\/[^\s]+)/g;
            content = content.replace(urlRegex, '<a href="$1" target="_blank">$1</a>');
            
            // Convert @mentions to links (if applicable)
            const mentionRegex = /@\[([^\]]+)\]/g;
            content = content.replace(mentionRegex, '<strong>@$1</strong>');
            
            return content;
        }
        return '';
    }
    
    handleToggleDetail(event) {
        event.preventDefault();
        this.isExpanded = !this.isExpanded;
        
        // Dispatch event to parent
        const toggleEvent = new CustomEvent('toggledetail', {
            detail: {
                recordId: this.timelineItem.recordId,
                isExpanded: this.isExpanded
            }
        });
        this.dispatchEvent(toggleEvent);
    }
    
    handleViewRecord(event) {
        event.preventDefault();
        
        // Navigate to the record
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.timelineItem.drilldownId,
                objectApiName: this.timelineItem.tooltipObject,
                actionName: 'view'
            }
        });
    }
    
    handleToggleComments(event) {
        event.preventDefault();
        this.showComments = !this.showComments;
    }
    
    handleToggleAttachments(event) {
        event.preventDefault();
        this.showAttachments = !this.showAttachments;
    }
    
    handleAddComment(event) {
        event.preventDefault();
        
        // Dispatch event to open comment composer
        const addCommentEvent = new CustomEvent('addcomment', {
            detail: {
                feedItemId: this.timelineItem.recordId
            }
        });
        this.dispatchEvent(addCommentEvent);
    }
    
    handleLike(event) {
        event.preventDefault();
        
        // Dispatch event to like the post
        const likeEvent = new CustomEvent('likepost', {
            detail: {
                feedItemId: this.timelineItem.recordId
            }
        });
        this.dispatchEvent(likeEvent);
    }
}
