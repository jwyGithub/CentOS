# Development configuration

## CentOS

1. 开启 BBR

```sh
bash <(curl -Lso- https://git.io/kernel.sh)
```

2. 更换 镜像源

```sh
bash <(curl -sSL https://raw.githubusercontent.com/SuperManito/LinuxMirrors/main/ChangeMirrors.sh)
```

3. Oracle Cloud centos 8 stream

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/jwyGithub/oh-my-dev/next/centos/oc_init.sh)"
```

4. 初始化 docker 容器

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/jwyGithub/oh-my-dev/next/docker/init.sh)"
```

5. ssl

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/jwyGithub/oh-my-dev/next/centos/cert.sh)"
```

## zsh

1. install zsh

-   ubuntu

```sh
sudo apt-get install zsh -y
```

-   centos

```sh
sudo yum install zsh -y
```

-   macos

```sh
brew install zsh
```

2. install oh-my-zsh

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

3. install dev-zsh.sh

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/jwyGithub/oh-my-dev/main/zsh/dev-zsh.sh)"
```

4. append proxy to ~/.zshrc

> macos

```sh
echo "$(curl https://raw.githubusercontent.com/jwyGithub/oh-my-dev/main/zsh/proxy/macos.zsh)" >> ~/.zshrc
```

> linux

```sh
echo "$(curl https://raw.githubusercontent.com/jwyGithub/oh-my-dev/main/zsh/proxy/linux.zsh)" >> ~/.zshrc
```

## node

```sh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/jwyGithub/oh-my-dev/main/node/install.sh)"
```

-   wsl 端口转发

```sh
netsh interface portproxy add v4tov4 listenport=80 listenaddress=0.0.0.0 connectport=80 connectaddress=1.1.1.1
```

