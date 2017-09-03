package main
import (
	"fmt"
	"os/exec"
	"net/http"
	"strings"
	"os"
)


type MyMux struct {
}
var wd,_ = os.Getwd()
func (p *MyMux) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path == "/" {
		http.ServeFile(w, r, "views/index.html")
	}else if strings.Contains(r.URL.Path , "views/"){
		http.ServeFile(w, r, wd+r.URL.Path)
	}else if strings.Contains(r.URL.Path , "monitor"){
		fmt.Println("收到信息")
		cmd :=  exec.Command("/bin/bash","-c" , "./webmonitor.sh") ///查看当前目录下文件
		msg, err := cmd.Output()
		if err != nil {
			fmt.Println("异常信息",err)
		}
		w.Write([]byte(msg))
	}else{
		http.NotFound(w, r)
	}
	return
}

func main() {
	mux := &MyMux{}
	fmt.Println("启动服务器，端口9091，注意端口别被占用了，同时webmonitor.sh已经赋予权限")
	http.ListenAndServe(":9091", mux)
}
