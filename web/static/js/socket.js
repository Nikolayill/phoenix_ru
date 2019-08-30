import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}});

socket.connect();


function renderComments(comments) {
    const renderedComments = comments.map(commentTemplate);
    document.querySelector(".collection").innerHTML = renderedComments.join("\n");
}

function renderComment(event) {
    const renderedComment = commentTemplate(event.comment);
    document.querySelector(".collection").innerHTML += (renderedComment+"\n");
}

function commentTemplate(comment) {
    return `<li class="collection-item">${comment.content}</li>`;
}

const createSocket = (topicId) => {
    let channel = socket.channel(`comments:${topicId}`, {});
    channel.join()
        .receive("ok", resp => {
            console.log("Joined successfully", resp.comments);
            renderComments(resp.comments);
        })
        .receive("error", resp => {
            console.log("Unable to join", resp)
        });

    channel.on(`comments:${topicId}:new`, renderComment);

    document.querySelector("button").addEventListener("click", () => {
            const content = document.querySelector("textarea").value;

            channel.push("comment:add", { content: content });
        });

};

window.createSocket = createSocket;

