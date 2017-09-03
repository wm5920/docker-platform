$.get('/monitor',function(ary){
    msg.data=ary.split("separator");
    for(var i=0;i<msg.data.length;i++){
        msg.data[i]=msg.data[i].trim();
    }
});

var msg=new Vue({
    el: '#msg',
    data: {
        data:""
    },
    filters: {
        trim: function(value) {
            return value.trim();
        }
    },
    methods: {

    }
});

$(".hadoop").click(function(){
    window.open(window.location.href.substring(0,window.location.href.lastIndexOf(":"))+":50070");
})
$(".hbase").click(function(){
    window.open(window.location.href.substring(0,window.location.href.lastIndexOf(":"))+":60010/master-status#baseStats");
})
$(".dubbo-monitor").click(function(){
    window.open(window.location.href.substring(0,window.location.href.lastIndexOf(":"))+":8080");
})
$(".dubbo-admin").click(function(){
    window.open(window.location.href.substring(0,window.location.href.lastIndexOf(":"))+":8482/dubbo-admin-2.8.4/");
})
$(".registry").click(function(){
    window.open(window.location.href.substring(0,window.location.href.lastIndexOf(":"))+":5000/v2/_catalog");
})
