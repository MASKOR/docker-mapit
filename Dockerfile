FROM fedora:27

# Install dependencies
RUN dnf install --assumeyes \
        boost-devel eigen3-devel cppzmq-devel OpenEXR-devel \
        protobuf protobuf-devel protobuf-lite-devel \
        cmake cmake-gui automake libtool gtest-devel gtest wget gcc-c++ \
        yaml-cpp-devel libuuid-devel \
        git \
        flann flann-devel libpcap-devel \
        blosc-devel blosc cppunit-devel cppunit-devel glfw-devel ilmbase-devel OpenEXR-devel tbb-devel python-devel libXi-devel \
        qt5 qt5-devel \
 && dnf groupinstall --assumeyes "Development Tools" "Development Libraries"

# Install PCL
RUN mkdir /root/ws \
 && cd /root/ws/ \
 && wget -q https://github.com/PointCloudLibrary/pcl/archive/pcl-1.8.1.tar.gz \
 && tar xfvz pcl-1.8.1.tar.gz \
 && cd pcl-pcl-1.8.1/ \
 && mkdir build \
 && cd build/ \
 && cmake .. -DWITH_VTK=false -DPCL_ENABLE_SSE=false \
 && make -j4 \
 && make -j4 install \
 && cd /root/ws \
 && rm -rf pcl-pcl-1.8.1/ pcl-1.8.1.tar.gz

# Instal ROS
RUN dnf install --assumeyes \
        python-empy poco-devel tinyxml2-devel lz4-devel urdfdom-headers-devel qhull-devel libuuid-devel urdfdom-devel collada-dom-devel yaml-cpp-devel \
        python-rosdep python-wstool python-rosinstall @buildsys-build python2-netifaces pyparsing python3-rosinstall_generator \
        tinyxml-devel python-qt5 python-qt5-devel assimp-devel ogre-devel python-defusedxml
RUN mkdir -p /opt/ros/catkin_ws/ \
 && cd /opt/ros/catkin_ws/ \
 && rosdep init \
 && rosdep update \
 && rosinstall_generator desktop --rosdistro kinetic --deps --wet-only --tar > kinetic-desktop-wet.rosinstall \
 && wstool init -j8 src kinetic-desktop-wet.rosinstall \
 && rosinstall_generator pcl_conversions --rosdistro kinetic --deps --wet-only --tar > kinetic-pcl_conversions-wet.rosinstall \
 && wstool merge -t src kinetic-pcl_conversions-wet.rosinstall \
 && wstool update -t src \
 && rosdep install --from-paths src --ignore-src --rosdistro kinetic -y
RUN cd /opt/ros/catkin_ws/ \
 && ./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release

RUN echo "source /opt/ros/catkin_ws/install_isolated/setup.bash" >> /root/.bashrc \
 && source /opt/ros/catkin_ws/install_isolated/setup.bash

# Install openVDB
RUN cd /root/ws/ \
 && wget -q https://github.com/dreamworksanimation/openvdb/archive/v4.0.2.tar.gz \
 && tar xfvz v4.0.2.tar.gz \
 && cd openvdb-4.0.2/ \
 && mkdir build \
 && cd build \
 && cmake .. -DGLFW_LIBRARY_PATH=/usr/lib64/ \
             -DIlmbase_IEX_LIBRARY=/usr/lib64/libIex.so \
             -DIlmbase_ILMTHREAD_LIBRARY=/usr/lib64/libIlmThread.so \
             -DOpenexr_ILMIMF_LIBRARY=/usr/lib64/libIlmImf.so \
             -DBLOSC_LOCATION=/usr/ \
             -DTBB_LOCATION=/usr/ \
             -DCPPUNIT_LOCATION=/usr/ \
             -DOPENEXR_LOCATION=/usr/ \
             -DILMBASE_LOCATION=/usr/ \
             -DUSE_GLFW3=true \
             -DGLFW3_LOCATION=/usr/ \
             -DOPENVDB_DISABLE_BOOST_IMPLICIT_LINKING=false \
             -DOPENVDB_ENABLE_3_ABI_COMPATIBLE=false \
 && make -j8 \
 && make install \
 && cd /root/ws \
 && rm -rf openvdb-4.0.2/ v4.0.2.tar.gz

# Install Json11
RUN cd /root/ws \
 && git clone https://github.com/dropbox/json11.git \
 && cd json11/ \
 && mkdir build \
 && cd build \
 && cmake .. -DCMAKE_CXX_FLAGS="-std=c++11" -DCMAKE_CXX_FLAGS_DEBUG="-g -std=c++11"  \
 && make -j8 \
 && make -j8 install \
 && cd /root/ws \
 && rm -rf json11/

# Install mapit
RUN source /opt/ros/catkin_ws/install_isolated/setup.bash \
 && cd /root/ws \
 && git clone --recursive https://github.com/MASKOR/mapit.git \
 && ldconfig \
 && cd mapit/ \
 && mkdir build \
 && cd build \
 && cmake .. -DCMAKE_CXX_FLAGS="-std=c++11" -DCMAKE_CXX_FLAGS_DEBUG="-g -std=c++11" \
             -DCMAKE_BUILD_TYPE=Debug \
             -DMAPIT_ENABLE_VISUALIZATION=false \
             -DWITH_LAS=false \
             -DHAVE_LASZIP=false \
             -DMAPIT_ENABLE_OPENVDB=true \
 && make -j8

# Run mapit test
RUN cd /root/ws/mapit/build/test/unit_tests/ \
 && ./TestAll \
 && if [ $? == 0 ]; then \
      echo -e "\n\n\033[0;32mMapit is working\033[0m"; \
    else \
      echo -e "\n\n\033[0;31mMapit is *not* working, test had $? errors\033[0m"; \
    fi

EXPOSE 5555
VOLUME ["/root/ws/mapit/build/tools/mapitd/.mapit"]

RUN mkdir /root/ws/scripts/
COPY mapit.sh /root/ws/scripts/
RUN chmod +x /root/ws/scripts/mapit.sh

ENTRYPOINT ["/root/ws/scripts/mapit.sh"]
